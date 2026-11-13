param(
    [string]$GameData = 'C:/Program Files (x86)/Steam/steamapps/common/Slay the Spire 2/data_sts2_windows_x86_64'
)

# Inspect real API metadata only. Constructing NCardPoolFilter (even uninitialized)
# can run a static constructor that needs Godot native functions in this game build.
$ErrorActionPreference = 'Stop'
$workspace = Split-Path (Split-Path $PSScriptRoot)
$env:APPDATA = Join-Path $workspace 'build/export_regression_test_appdata'
foreach ($name in @('GodotSharp', 'sts2', '0Harmony')) {
    [void][Reflection.Assembly]::LoadFrom((Join-Path $GameData "$name.dll"))
}
$assembly = [Reflection.Assembly]::LoadFrom((Join-Path $workspace 'tools/CardArtEditorBootstrap/bin/Release/net8.0/card_art_editor.dll'))
$instance = [Reflection.BindingFlags]'Instance,Public,NonPublic'
$static = [Reflection.BindingFlags]'Static,Public,NonPublic'
$script:checks = 0
function Assert-True($Condition, [string]$Message) {
    $script:checks++
    if (!$Condition) { throw $Message }
}
$library = [MegaCrit.Sts2.Core.Nodes.Screens.CardLibrary.NCardLibrary]
$grid = [MegaCrit.Sts2.Core.Nodes.Screens.CardLibrary.NCardLibraryGrid]
$filter = [MegaCrit.Sts2.Core.Nodes.Screens.CardLibrary.NCardPoolFilter]
$model = [MegaCrit.Sts2.Core.Models.CardModel]
$filtersType = [Collections.Generic.Dictionary[MegaCrit.Sts2.Core.Nodes.Screens.CardLibrary.NCardPoolFilter, Func[MegaCrit.Sts2.Core.Models.CardModel, bool]]]
Assert-True ($library.GetField('_poolFilters', $instance).FieldType -eq $filtersType) 'Pool filter API changed.'
Assert-True ($library.GetField('_grid', $instance).FieldType -eq $grid) 'Library grid API changed.'
$allCards = $grid.GetField('_allCards', $instance)
Assert-True ([Collections.Generic.IEnumerable[MegaCrit.Sts2.Core.Models.CardModel]].IsAssignableFrom($allCards.FieldType)) 'Unfiltered compendium list API changed.'
Assert-True ($filter.GetProperty('IsSelected', $instance).PropertyType -eq [bool]) 'Tab selection API changed.'
$loc = $filter.GetProperty('Loc', $instance).PropertyType
Assert-True ($null -ne $loc.GetMethod('GetFormattedText', [Type[]]@())) 'Category name localization API changed.'
Assert-True ($library.GetMethod('IsVisibleInTree', $instance).ReturnType -eq [bool]) 'Visible library API changed.'
Assert-True ($model.GetProperty('PortraitPath', $instance).PropertyType -eq [string]) 'Card source path API changed.'
Assert-True ([Collections.Generic.IEnumerable[string]].IsAssignableFrom($model.GetProperty('AllPortraitPaths', $instance).PropertyType)) 'State-dependent portrait API changed.'
Assert-True ($model.GetProperty('HasBetaPortrait', $instance).PropertyType -eq [bool]) 'Beta portrait availability API changed.'
Assert-True ($model.GetProperty('BetaPortraitPath', $instance).PropertyType -eq [string]) 'Beta portrait path API changed.'
$bridge = $assembly.GetType('CardArtEditorBootstrap.CardLibraryExportBridge', $true)
Assert-True ($null -ne $bridge.GetMethod('Bind', $static)) 'Export request bridge missing from DLL.'
$select = $bridge.GetMethod('TryGetSelectedCategory', $static)
Assert-True ($select.ReturnType -eq [bool] -and $select.GetParameters().Count -eq 3) 'Category snapshot method missing.'
Write-Output "Library export bridge: $script:checks API checks passed (metadata only; no native UI)."
