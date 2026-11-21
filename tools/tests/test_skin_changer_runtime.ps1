param([Parameter(Mandatory)][string]$SkinChangerDll)
$ErrorActionPreference = 'Stop'
$workspace = Split-Path (Split-Path $PSScriptRoot)
$env:APPDATA = Join-Path $workspace 'build/skin_changer_interop_test_appdata'
$data = 'C:/Program Files (x86)/Steam/steamapps/common/Slay the Spire 2/data_sts2_windows_x86_64'
foreach ($name in @('GodotSharp', 'sts2', '0Harmony')) { [void][Reflection.Assembly]::LoadFrom((Join-Path $data "$name.dll")) }
$sc = [Reflection.Assembly]::LoadFrom((Resolve-Path $SkinChangerDll))
$cae = [Reflection.Assembly]::LoadFrom((Join-Path $workspace 'tools/CardArtEditorBootstrap/bin/Release/net8.0/card_art_editor.dll'))
$static = [Reflection.BindingFlags]'Static,Public,NonPublic'
$instance = [Reflection.BindingFlags]'Instance,Public,NonPublic'
function Assert-True($Condition, [string]$Message) { if (!$Condition) { throw $Message } }
$service = $sc.GetType('STS2SkinChanger.Core.SkinService', $true)
$runtime = $cae.GetType('CardArtEditorBootstrap.SkinChangerRuntimeBridge', $true)
$config = $service.GetProperty('Config', $static).GetValue($null)
$config.Selections['cards:ironclad'] = 'other_mod'
$config.Selections['cards:item:card.strike_ironclad'] = '__base__'
$before = $config.Selections | ConvertTo-Json -Compress

# Seed metadata-only cache entries: no Godot native objects are constructed.
$identity = $service.GetField('ExternalCardProviderIdentityPaths', $static).GetValue($null)
$owned = "ironclad`ncae_saved_art`nconfig`nres://portrait.png"
$other = "ironclad`nother_mod`nconfig`nres://portrait.png"
$identity[$owned] = 'owned'
$identity[$other] = 'other'
$failed = $service.GetField('FailedCardPortraitRequests', $static).GetValue($null)
[void]$failed.Add($owned)
[void]$failed.Add($other)
$session = $service.GetField('SessionCardPortraits', $static)
if ($null -ne $session) {
    $session = $session.GetValue($null)
    $type = $session.GetType()
    $entries = $type.GetField('_entries', $instance).GetValue($session)
    $lru = $type.GetField('_lruOrder', $instance).GetValue($session)
    $refs = $type.GetField('_backingTextureRefCounts', $instance).GetValue($session)
    $entryType = $type.GetNestedType('Entry', [Reflection.BindingFlags]'NonPublic')
    $constructor = $entryType.GetConstructors($instance)[0]
    $id = [ulong]1
    foreach ($key in @("raw`n$owned", "raw`n$other")) {
        $node = $lru.AddLast([string]$key)
        $entry = $constructor.Invoke([object[]]@($null, $id, [long]64, $node))
        $entries.Add($key, $entry)
        $refs[$id] = 1
        $id++
    }
    $type.GetField('_estimatedBytes', $instance).SetValue($session, [long]128)
}
$runtime.GetMethod('InvalidateTextures', $static).Invoke($null, [object[]]@($service))
Assert-True (!$identity.ContainsKey($owned) -and $identity.ContainsKey($other)) 'Another provider lost its identity cache.'
Assert-True (!$failed.Contains($owned) -and $failed.Contains($other)) 'Failure invalidation affected another provider.'
if ($null -ne $session) {
    Assert-True ($entries.Count -eq 1 -and $entries.ContainsKey("raw`n$other")) 'Session cache retained stale CAE pixels or evicted another provider.'
    Assert-True ($lru.Count -eq 1 -and $refs.Count -eq 1) 'Session LRU/refcounts were corrupted.'
    Assert-True ($type.GetField('_estimatedBytes', $instance).GetValue($session) -eq 64) 'Session memory accounting was corrupted.'
}
Assert-True (($config.Selections | ConvertTo-Json -Compress) -eq $before) 'Refreshing CAE changed user selections.'
Assert-True ($null -eq $cae.GetType('CardArtEditorBootstrap.Bootstrap').GetMethod('ApplySkinChangerPackSelections', $static)) 'Forced category promotion was reintroduced.'

$gif = $cae.GetType('CardArtEditorBootstrap.SkinChangerGifBridge')
$legacy = [Reflection.Emit.DynamicMethod]::new('LegacyLoad', [Godot.Texture2D], [Type[]]@([string],[string],[bool]))
[void]$legacy.DefineParameter(1, [Reflection.ParameterAttributes]::None, 'selection')
[void]$legacy.DefineParameter(2, [Reflection.ParameterAttributes]::None, 'resourcePath')
[void]$legacy.DefineParameter(3, [Reflection.ParameterAttributes]::None, 'useSelectedProvider')
$select = $gif.GetMethod('SelectPortraitPostfix', $static)
Assert-True ($select.Invoke($null, [object[]]@($legacy)).Name -eq 'TagAnimation') 'Legacy GIF API is unsupported.'
$current = $service.GetMethod('LoadIsolatedCardPortrait', $static)
$expected = if ($current.GetParameters().Count -eq 1) { 'TagRequestAnimation' } else { 'TagAnimation' }
Assert-True ($select.Invoke($null, [object[]]@($current)).Name -eq $expected) 'Installed GIF API selected the wrong adapter.'

# Exercise the real parser on a worker, including an edit during an in-flight scan.
$folder = Join-Path $env:APPDATA 'async_fixture'
[void][IO.Directory]::CreateDirectory($folder)
$path = Join-Path $folder 'fixture.cardartpack.json'
[IO.File]::WriteAllText($path, '{"format":"card_art_bundle","overrides":[]}')
$loader = $cae.GetType('CardArtEditorBootstrap.SkinChangerPackLoader')
$read = $loader.GetMethod('TryRead', $static)
$args = [object[]]@($sc, [string[]]@($folder), $null)
Assert-True (!$read.Invoke($null, $args)) 'The first scan unexpectedly blocked to completion.'
[IO.File]::AppendAllText($path, ' ')
$complete = $false
for ($tick = 0; $tick -lt 200; $tick++) {
    Start-Sleep -Milliseconds 10
    if ($read.Invoke($null, $args)) { $complete = $true; break }
}
Assert-True ($complete -and $null -ne $args[2]) 'Background scan failed or never completed.'
Write-Output 'Runtime bridge passed: provider-only eviction, session accounting, selection preservation, old/new GIF adapters, background scan supersession.'
