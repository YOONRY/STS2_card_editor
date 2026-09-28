param(
    [string]$SkinChangerDll,
    [string]$GameData = 'C:/Program Files (x86)/Steam/steamapps/common/Slay the Spire 2/data_sts2_windows_x86_64'
)

# Run under PowerShell 7 on .NET 9+; no game or Godot native runtime is started.
$ErrorActionPreference = 'Stop'
$workspace = Split-Path (Split-Path $PSScriptRoot)
$env:APPDATA = Join-Path $workspace 'build/skin_changer_interop_test_appdata'
if (!$SkinChangerDll) { throw 'Pass the installed Skin Changer DLL to test its real API.' }
foreach ($name in @('GodotSharp', 'sts2', '0Harmony')) {
    [void][Reflection.Assembly]::LoadFrom((Join-Path $GameData "$name.dll"))
}
$sc = [Reflection.Assembly]::LoadFrom((Resolve-Path $SkinChangerDll))
$cae = [Reflection.Assembly]::LoadFrom((Join-Path $workspace 'tools/CardArtEditorBootstrap/bin/Release/net8.0/card_art_editor.dll'))
$static = [Reflection.BindingFlags]'Static,Public,NonPublic'
$instance = [Reflection.BindingFlags]'Instance,Public,NonPublic'
$bootstrap = $cae.GetType('CardArtEditorBootstrap.Bootstrap', $true)
$service = $sc.GetType('STS2SkinChanger.Core.SkinService', $true)
$adapter = $cae.GetType('CardArtEditorBootstrap.SkinChangerCatalogBridge', $true)
function Assert-True($Condition, [string]$Message) {
    if (!$Condition) { throw $Message }
}

# The game's Harmony supports CoreCLR 9, not the PowerShell host's CoreCLR 10.
# Still exercise the real catalog/cache API on 10; do not claim a detour test.
$bridge = $sc.GetType('STS2SkinChanger.Core.ExternalCardVisualBridge', $true)
$ownershipMethod = $bridge.GetMethod('GetScriptedManagerOwnership', $static)
Assert-True ($ownershipMethod.ReturnType.IsValueType) 'Ownership is no longer a defaultable value type.'
Assert-True ($null -ne $bridge.GetMethod('SynchronizeProvider', $static)) 'Provider callback API changed.'
if ([Environment]::Version.Major -eq 9) {
    Assert-True ($bootstrap.GetMethod('InstallSkinChangerOwnershipHooks', $static).Invoke($null, @())) 'Ownership hooks were not installed.'
} else {
    Write-Warning 'Native Harmony detours skipped outside CoreCLR 9; callback policy and real catalog are tested below.'
}
$bootstrap.GetField('_skinChangerOwnsVisuals', $static).SetValue($null, $true)
if ([Environment]::Version.Major -eq 9) {
    $ownership = $ownershipMethod.Invoke($null, [object[]]@($null))
    foreach ($property in @('Portrait', 'Frame', 'Text')) {
        Assert-True (!$ownership.GetType().GetProperty($property).GetValue($ownership)) "CAE still claims $property ownership."
    }
    $bridge.GetMethod('SynchronizeProvider', $static).Invoke($null, [object[]]@($null))
}
Assert-True (!$bootstrap.GetMethod('AllowSkinChangerEditorCallback', $static).Invoke($null, @())) 'Skin Changer can call the competing CAE renderer.'
$bootstrap.GetField('_skinChangerOwnsVisuals', $static).SetValue($null, $false)
Assert-True ($bootstrap.GetMethod('AllowSkinChangerEditorCallback', $static).Invoke($null, @())) 'Standalone CAE callbacks were disabled.'

# Same-path replacement needs a new isolated alias, not just a decoded cache miss.
$cache = $service.GetField('IsolatedCardOverlayCache', $static).GetValue($null)
$stateType = $service.GetNestedType('IsolatedCardOverlayState', [Reflection.BindingFlags]'NonPublic')
foreach ($key in @("ironclad`ncae_saved_art`nprovider", "silent`ncae_saved_art`nprovider", "ironclad`nother_mod`nprovider", "__base__`nbase")) {
    $state = [Activator]::CreateInstance($stateType, [object[]]@($key))
    $cache.Add($key, $state)
}
$bootstrap.GetMethod('InvalidateSkinChangerPackResources', $static).Invoke($null, [object[]]@($service))
Assert-True ($cache.Count -eq 2) 'Pack refresh invalidated the wrong resource aliases.'
Assert-True ($cache.ContainsKey("ironclad`nother_mod`nprovider") -and $cache.ContainsKey("__base__`nbase")) 'Unrelated providers were evicted.'

# Use the real parser and catalog. No extracted/reimplemented Skin Changer code.
$catalogType = $sc.GetType('STS2SkinChanger.Catalog.SkinCatalog', $true)
$catalog = [Runtime.CompilerServices.RuntimeHelpers]::GetUninitializedObject($catalogType)
foreach ($fieldName in @('_artPackCardGroups', '_cardGroups', '_workshopSourceIds')) {
    $field = $catalogType.GetField($fieldName, $instance)
    $field.SetValue($catalog, [Activator]::CreateInstance($field.FieldType))
}
foreach ($fieldName in @('_configuredCardGroups', '_pckCardOptions')) {
    $field = $catalogType.GetField($fieldName, $instance)
    $field.SetValue($catalog, [Array]::CreateInstance($field.FieldType.GenericTypeArguments[0], 0))
}
$entryType = $sc.GetType('STS2SkinChanger.Catalog.CardCatalogEntry', $true)
$entries = [Array]::CreateInstance($entryType, 4)
$entries[0] = [Activator]::CreateInstance($entryType, [object[]]@('StrikeIronclad', 'res://images/packed/card_portraits/ironclad/strike_ironclad.png', 'ironclad', 'ironclad', 'ironclad'))
$entries[1] = [Activator]::CreateInstance($entryType, [object[]]@('DefendIronclad', 'res://images/packed/card_portraits/ironclad/defend_ironclad.png', 'ironclad', 'ironclad', 'ironclad'))
$entries[2] = [Activator]::CreateInstance($entryType, [object[]]@('Corruption', 'res://images/packed/card_portraits/ironclad/corruption.png', 'ironclad', 'ironclad', 'ancients'))
$entries[3] = [Activator]::CreateInstance($entryType, [object[]]@('TheSmith', 'res://images/packed/card_portraits/regent/the_smith.png', 'regent', 'regent', 'ancients'))
$policy = $sc.GetType('STS2SkinChanger.Catalog.CardArtPackScanPolicy', $true)
$packType = $sc.GetType('STS2SkinChanger.Catalog.CardArtPack', $true)
function Attach-TestPack([string]$Id, [string]$CardStem, [int]$Width, [int]$Height, [string]$Mode = 'default', [string]$Root = 'C:/test', [switch]$StartupHook) {
    $png = [byte[]]::new(24)
    ([byte[]]@(137,80,78,71,13,10,26,10)).CopyTo($png, 0)
    $w = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($Width))
    $h = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($Height))
    $w.CopyTo($png, 16)
    $h.CopyTo($png, 20)
    $encoded = [Convert]::ToBase64String($png)
    $json = @{overrides=@(@{source_path="res://images/packed/card_portraits/ironclad/$CardStem.png"; png_base64=$encoded; edit_source_png_base64=$encoded; display_mode=$Mode; type='static'})} | ConvertTo-Json -Depth 5
    $cards = $policy.GetMethod('ParseCards', $static).Invoke($null, [object[]]@([string]$json))
    $pack = [Activator]::CreateInstance($packType, [object[]]@($Id, $Id, "$Id.cardartpack.json", $Root, $cards))
    $packs = [Array]::CreateInstance($packType, 1)
    $packs[0] = $pack
    [void]$catalogType.GetMethod('AttachCardArtPacks', $instance).Invoke($catalog, [object[]]@($packs, $entries))
    if ($StartupHook) {
        $startup.GetMethod('ConfigureAttachedPack', $static).Invoke($null, [object[]]@($catalog, $packs, $entries))
    } else {
        $adapter.GetMethod('ConfigurePresentations', $static).Invoke($null, [object[]]@($catalog, $entries, $packs))
    }
    $catalogType.GetMethod('FinalizeCardGroups', $instance).Invoke($catalog, [object[]](,$entries))
}
function Get-TestOption([string]$Id, [string]$Group = 'ironclad') {
    $groups = $catalogType.GetProperty('CardGroups', $instance).GetValue($catalog)
    return ($groups | Where-Object Id -eq $Group).Options | Where-Object Id -eq $Id
}
Attach-TestPack 'other_mod' 'defend_ironclad' 24 36
Attach-TestPack 'cae_saved_art' 'strike_ironclad' 24 18
$option = Get-TestOption 'cae_saved_art'
Assert-True ($option.NormalPortraits.Count -eq 1 -and $option.NormalPortraits.ContainsKey('StrikeIronclad')) 'CAE entry leaked to another card.'
Assert-True (!$option.CardPresentations['StrikeIronclad'].UseAncientLayout -and !$option.CardPresentations['StrikeIronclad'].UseExpandedPortraitLayout) 'Regular rendered pixels acquired a full-art layout.'
$remove = $bootstrap.GetMethod('RemoveSkinChangerPackOptions', $static)
[void]$remove.Invoke($null, [object[]]@($catalog, $catalogType, 'cae_saved_art'))
Attach-TestPack 'cae_saved_art' 'strike_ironclad' 24 18 'full_art'
Assert-True ((Get-TestOption 'cae_saved_art').CardPresentations['StrikeIronclad'].UseAncientLayout) 'Explicit full-art mode was ignored.'
Assert-True ($null -ne (Get-TestOption 'other_mod')) 'CAE update removed a different provider.'
[void]$remove.Invoke($null, [object[]]@($catalog, $catalogType, 'cae_saved_art'))
Attach-TestPack 'cae_saved_art' 'strike_ironclad' 24 18
Attach-TestPack 'cae_saved_art' 'corruption' 18 24
Attach-TestPack 'cae_saved_art' 'the_smith' 18 24
$ancients = Get-TestOption 'cae_saved_art' 'ancients'
Assert-True ($ancients.NormalPortraits.ContainsKey('Corruption') -and $ancients.NormalPortraits.ContainsKey('TheSmith')) 'Native Ancient cards were not mirrored from both character pools.'
Assert-True (!$ancients.NormalPortraits.ContainsKey('StrikeIronclad')) 'Regular cards leaked into the Ancient filter.'
Assert-True ($ancients.CardPresentations['Corruption'].UseAncientLayout) 'Native Ancient layout was lost in default mode.'
Assert-True (!(Get-TestOption 'cae_saved_art' 'regent').NormalPortraits.ContainsKey('Corruption')) 'An Ancient image crossed character pool boundaries.'
[void]$remove.Invoke($null, [object[]]@($catalog, $catalogType, 'cae_saved_art'))
$catalogType.GetMethod('FinalizeCardGroups', $instance).Invoke($catalog, [object[]](,$entries))
Assert-True ($null -eq (Get-TestOption 'cae_saved_art')) 'Restored CAE cards remain in the catalog.'
Assert-True ($null -eq (Get-TestOption 'cae_saved_art' 'ancients')) 'Restored Ancient cards remain in the filter group.'
Assert-True ($null -ne (Get-TestOption 'other_mod')) 'Restoring CAE cards removed the fallback provider.'

# Filter only a registered import's exact Skin Changer identity/root, and undo
# that filter when the import is unregistered. Do not delete a provider's files.
$fixture = Join-Path $workspace 'build/skin_changer_interop_test_appdata/import_fixture'
[void][IO.Directory]::CreateDirectory($fixture)
$importPath = Join-Path $fixture 'ironclad-full-art.cardartpack.json'
[IO.File]::WriteAllText($importPath, '{"format":"card_art_bundle","overrides":[]}')
Attach-TestPack 'card_art_pack' 'strike_ironclad' 18 24 'default' $fixture
Attach-TestPack 'unimported_pack' 'defend_ironclad' 18 24 'default' $fixture
$filter = $adapter.GetMethod('FilterImportedPacks', $static)
[void]$filter.Invoke($null, [object[]]@($catalog, [string[]]@($importPath)))
$catalogType.GetMethod('FinalizeCardGroups', $instance).Invoke($catalog, [object[]](,$entries))
Assert-True ($null -eq (Get-TestOption 'card_art_pack')) 'A registered imported pack still appears separately.'
Assert-True ($null -ne (Get-TestOption 'unimported_pack') -and $null -ne (Get-TestOption 'other_mod')) 'Filtering removed an unrelated provider.'
[void]$filter.Invoke($null, [object[]]@($catalog, [string[]]@($importPath)))
[void]$filter.Invoke($null, [object[]]@($catalog, [string[]]@()))
$catalogType.GetMethod('FinalizeCardGroups', $instance).Invoke($catalog, [object[]](,$entries))
Assert-True ($null -ne (Get-TestOption 'card_art_pack')) 'Unregistering an import did not restore its independent provider.'
Write-Output 'Real Skin Changer API regression passed: ownership policy, aliases, full-art flags, Ancient groups, pack filtering, restoration.'

# Startup filtering occurs on paths, before the scanner decodes any pack bytes.
$startup = $cae.GetType('CardArtEditorBootstrap.SkinChangerStartupBridge', $true)
$registryPath = Join-Path $fixture 'art_pack_registry.json'
[IO.File]::WriteAllText($registryPath, (@{
    packs = @{ registered = @{} }
    workshop_sources = @{
        first = @{ pack_id = 'registered'; path = $importPath }
        removed = @{ pack_id = ''; path = (Join-Path $fixture 'removed.cardartpack.json') }
    }
} | ConvertTo-Json -Depth 6))
$imports = $startup.GetMethod('ReadImportedPaths', $static).Invoke($null, [object[]]@([string]$registryPath))
Assert-True ($imports.Count -eq 1) 'Startup filter included removed/unregistered packs.'
[void]$startup.GetMethod('UpdateImportedPaths', $static).Invoke($null, [object[]](,[string[]]@($importPath)))
$unrelated = Join-Path $fixture 'unimported.cardartpack.json'
$filterArgs = [object[]](,[string[]]@($importPath, $unrelated))
$startup.GetMethod('FilterPackFiles', $static).Invoke($null, $filterArgs)
$filtered = @($filterArgs[0])
Assert-True ($filtered.Count -eq 1 -and $filtered[0] -eq $unrelated) 'Initial enumeration exposed a registered imported pack or hid another pack.'
$released = $startup.GetMethod('UpdateImportedPaths', $static).Invoke($null, [object[]](,[string[]]@()))
Assert-True (@($released).Count -eq 1) 'Unregistering did not schedule restoration of the skipped pack.'
$startup.GetMethod('MarkPublished', $static).Invoke($null, [object[]]@($catalog, [string]$fixture))
Assert-True ($startup.GetMethod('IsPublished', $static).Invoke($null, [object[]]@($catalog, [string]$fixture, [string[]]@()))) 'An unchanged initial catalog would be scanned twice.'
Assert-True (!$startup.GetMethod('IsPublished', $static).Invoke($null, [object[]]@($catalog, [string]$fixture, [string[]]@($importPath)))) 'Import registration changes were skipped as unchanged.'
$generatedPath = Join-Path $fixture 'cae_saved_art.cardartpack.json'
[IO.File]::WriteAllText($generatedPath, '{"format":"card_art_bundle","overrides":[]}')
$startup.GetMethod('MarkPublished', $static).Invoke($null, [object[]]@($catalog, [string]$fixture))
[IO.File]::AppendAllText($generatedPath, ' ')
Assert-True (!$startup.GetMethod('IsPublished', $static).Invoke($null, [object[]]@($catalog, [string]$fixture, [string[]]@()))) 'An updated unified file was mistaken for an already loaded pack.'
$startup.GetField('_packDirectory', $static).SetValue($null, [string]$fixture)
$rootArgs = [object[]](,[string[]]@('C:/unrelated'))
$startup.GetMethod('AddUnifiedRoot', $static).Invoke($null, $rootArgs)
Assert-True (@($rootArgs[0]).Count -eq 2 -and @($rootArgs[0]) -contains $fixture) 'Initial scan did not include the unified pack directory.'
Attach-TestPack 'cae_saved_art' 'strike_ironclad' 24 18 'full_art' -StartupHook
Assert-True ((Get-TestOption 'cae_saved_art').CardPresentations['StrikeIronclad'].UseAncientLayout) 'Initial attach did not retain full-art presentation.'
Attach-TestPack 'cae_saved_art' 'corruption' 18 24 -StartupHook
Assert-True ((Get-TestOption 'cae_saved_art' 'ancients').NormalPortraits.ContainsKey('Corruption')) 'Initial attach omitted the Ancient group.'
Attach-TestPack 'other_mod' 'defend_ironclad' 24 18 -StartupHook
Assert-True ((Get-TestOption 'cae_saved_art').CardPresentations['StrikeIronclad'].UseAncientLayout) 'An unrelated attach disabled CAE full art.'
Write-Output 'Startup regression passed: early path filtering, unrelated packs, unregister restoration, duplicate refresh detection.'
