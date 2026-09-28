using System;
using System.Collections;
using System.IO;
using System.Collections.Generic;
using System.Reflection;
using System.Runtime.CompilerServices;
using Godot;
using HarmonyLib;
using MegaCrit.Sts2.Core.Modding;
using MegaCrit.Sts2.Core.Models;
using MegaCrit.Sts2.Core.Models.Exceptions;
using MegaCrit.Sts2.Core.Nodes.Cards;
using MegaCrit.Sts2.Core.Nodes.Screens;

namespace CardArtEditorBootstrap;

[ModInitializer("Init")]
public static class Bootstrap
{
    private const string HarmonyId = "ysg05.card_art_editor";
    private static readonly Harmony Harmony = new(HarmonyId);
    private static bool _loggedManagerLoadFailure;
    private static bool _loggedManagerInstantiateFailure;
    private static bool _loggedOverlayLoadFailure;
    private const string ManagerNodeName = "CardArtOverrideManager";
    private const string ManagerScriptPath = "res://mods/card_art_editor/card_art_override_manager.gd";
    private const string OverlayScenePath = "res://mods/card_art_editor/inspect_card_art_editor.tscn";
    internal const string InspectSourcePathMeta = "_card_art_inspect_source_path";
    internal const string InspectCardIdMeta = "_card_art_inspect_card_id";
    internal const string InspectCardNodePathMeta = "_card_art_inspect_card_node_path";
    internal const string InspectBaseGameModelMeta = "_card_art_model_is_base_game";
    internal const string InspectModelOwnerMeta = "_card_art_model_owner";
    internal const string InspectModelRarityMeta = "_card_art_model_rarity";
    private const string CachedPortraitPathMeta = "_card_art_cached_portrait_path";
    private const string CachedPortraitCardIdMeta = "_card_art_cached_portrait_card_id";
    private const string CachedPortraitModelKeyMeta = "_card_art_cached_portrait_model_key";
    private const string DeferredCardRefreshPendingMeta = "_card_art_deferred_card_refresh_pending";
    private const string DeferredCardRefreshInvalidateModelMeta = "_card_art_deferred_card_refresh_invalidate_model";
    private const string ManagerRefreshModeMeta = "_card_art_event_refresh_configured";
    private const string SkinBridgeRuntimeCheckMeta = "_card_art_bridge_runtime_checked";
    private const string SkinBridgeSkinRootMeta = "_card_art_bridge_skin_root";
    private const string SkinBridgeCaeRootMeta = "_card_art_bridge_cae_root";
    private const string SkinBridgeSignalConnectedMeta = "_card_art_bridge_signal_connected";
    private const string SkinBridgePackPublishedSignal = "skin_changer_pack_published";
    private const string SkinBridgePackId = "cae_saved_art";
    private const string SkinChangerAssemblyName = "Gurio.SkinChanger";
    private const string InfectionEffectSuppressedMeta = "_card_art_infection_effect_suppressed";
    private const string InfectionEffectOriginalVisibleMeta = "_card_art_infection_effect_original_visible";
    private const string NativeAncientLayoutReloadingMeta = "_card_art_native_ancient_layout_reloading";
    private const int AncientCardRarityValue = 5;
    private static readonly MethodInfo? NCardReloadMethod = AccessTools.Method(typeof(NCard), "Reload");
    private static Node? _pendingManager;
    private static bool _eventDrivenPortraitRefreshEnabled;
    private static MethodBase? _nCardUpdateVisualsMethod;
    private static bool _externalUpdateVisualsPatchDetected;
    private static long _nextExternalPatchProbeTicks;
    private const long ExternalPatchProbeIntervalMs = 1000;
    private static readonly Dictionary<Type, MemberInfo?> CardNodeMemberCache = new();
    private static readonly Dictionary<Type, PropertyInfo?> CustomPortraitPathPropertyCache = new();
    private static string _lastInspectMetadataDiagnostic = string.Empty;
    private static string _skinChangerRoot = string.Empty;
    private static string _cardArtEditorRoot = string.Empty;
    private static long _nextSkinChangerProbeTicks;
    private const long SkinChangerProbeIntervalMs = 2000;
    private static Callable _skinChangerPackPublishedCallable;
    private static bool _skinChangerPackPublishedCallableReady;
    private static string _pendingSkinChangerPackDirectory = string.Empty;
    private static readonly HashSet<string> PendingSkinChangerChangedSources = new(StringComparer.OrdinalIgnoreCase);
    private static bool _skinChangerCatalogRefreshActive;
    private static bool _skinChangerOwnershipHooksInstalled;
    private static bool _skinChangerOwnsVisuals;
    private static long _nextSkinChangerCatalogRefreshTicks;
    private static string _lastSkinChangerCatalogRefreshError = string.Empty;

    public static void Init()
    {
        try
        {
            Log("Init start.");
            Harmony.PatchAll(typeof(Bootstrap).Assembly);
            var essential = AccessTools.Method("MegaCrit.Sts2.Core.Helpers.OneTimeInitialization:ExecuteEssential");
            if (essential is not null)
            {
                Harmony.Patch(essential, prefix: new HarmonyMethod(typeof(Bootstrap), nameof(PrepareSkinChangerStartup)) { priority = Priority.First });
            }
            PatchOptionalCardVisualHooks();
            _eventDrivenPortraitRefreshEnabled = true;
            var manager = TryEnsureManager();
            if (manager is not null && HasExternalUpdateVisualsPatch())
            {
                manager.Call("set_external_provider_capture_enabled", true);
            }
            else
            {
                // Probe again on the first card update in case the other mod initializes later.
                _nextExternalPatchProbeTicks = 0;
            }
            TryAttachToOpenInspectScreens();
            Log("Init complete.");
        }
        catch (Exception ex)
        {
            Log("Init failed: " + ex);
            GD.PushError($"CardArtEditor: bootstrap failed: {ex}");
        }
    }

    private static void PatchOptionalCardVisualHooks()
    {
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Cards.NCard", "UpdateVisuals", nameof(CaptureCardProviderPostfix), Priority.Last);
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Cards.NCard", "_EnterTree", nameof(CaptureCardProviderPostfix), Priority.Last);
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Cards.NCard", "set_Model", nameof(RefreshCardOwnerPostfix), Priority.Last);
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Cards.Holders.NCardHolder", "ReassignToCard", nameof(RefreshCardOwnerPostfix));
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Cards.Holders.NCardHolder", "SetCard", nameof(RefreshCardOwnerPostfix));
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Cards.Holders.NCardHolder", "OnCardReassigned", nameof(RefreshCardOwnerPostfix));
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Cards.Holders.NGridCardHolder", "OnCardReassigned", nameof(RefreshCardOwnerPostfix), Priority.Last);
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Cards.Holders.NGridCardHolder", "OnReturnedFromPool", nameof(RefreshCardOwnerPostfix), Priority.Last);
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Cards.Holders.NGridCardHolder", "SetIsPreviewingUpgrade", nameof(RefreshCardOwnerPostfix), Priority.Last);
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Multiplayer.NMultiplayerCardIntent", "_Ready", nameof(RefreshCardOwnerPostfix));
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Vfx.NCardFlyPowerVfx", "Create", nameof(RefreshCardOwnerPostfix));
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Vfx.NCardFlyPowerVfx", "_Ready", nameof(RefreshCardOwnerPostfix));
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Vfx.NCardFlyVfx", "Create", nameof(RefreshCardOwnerPostfix));
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Vfx.NCardFlyVfx", "_Ready", nameof(RefreshCardOwnerPostfix));
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Vfx.Cards.NCardExhaustQuickVfx", "Create", nameof(RefreshCardOwnerPostfix));
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Vfx.Cards.NCardExhaustVfx", "Create", nameof(RefreshCardOwnerPostfix));
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Vfx.NCardSmithVfx", "Create", nameof(RefreshCardOwnerPostfix));
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Vfx.NCardSmithVfx", "_Ready", nameof(RefreshCardOwnerPostfix));
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Vfx.NCardEnchantVfx", "_Ready", nameof(RefreshCardOwnerPostfix));
    }

    private static void TryPatchOptionalPostfix(string typeName, string methodName, string postfixName, int priority = Priority.Normal)
    {
        try
        {
            var type = AccessTools.TypeByName(typeName);
            if (type is null)
            {
                Log($"Optional patch skipped: type not found {typeName}.");
                return;
            }

            const BindingFlags flags =
                BindingFlags.Public |
                BindingFlags.NonPublic |
                BindingFlags.Instance |
                BindingFlags.Static |
                BindingFlags.DeclaredOnly;
            MethodInfo? target = null;
            var matchCount = 0;
            foreach (var method in type.GetMethods(flags))
            {
                if (!string.Equals(method.Name, methodName, StringComparison.Ordinal))
                {
                    continue;
                }

                target = method;
                matchCount++;
            }

            if (target is null)
            {
                Log($"Optional patch skipped: method not found {typeName}.{methodName}.");
                return;
            }

            if (matchCount != 1)
            {
                Log($"Optional patch skipped: ambiguous method {typeName}.{methodName} ({matchCount} matches).");
                return;
            }

            if (target.IsAbstract)
            {
                Log($"Optional patch skipped: abstract method {typeName}.{methodName}.");
                return;
            }

            if (string.Equals(typeName, "MegaCrit.Sts2.Core.Nodes.Cards.NCard", StringComparison.Ordinal) &&
                string.Equals(methodName, "UpdateVisuals", StringComparison.Ordinal))
            {
                _nCardUpdateVisualsMethod = target;
            }

            var postfix = typeof(Bootstrap).GetMethod(postfixName, BindingFlags.NonPublic | BindingFlags.Static);
            if (postfix is null)
            {
                Log($"Optional patch skipped: postfix not found {postfixName}.");
                return;
            }

            Harmony.Patch(target, postfix: new HarmonyMethod(postfix) { priority = priority });
            Log($"Optional patch applied: {typeName}.{methodName}.");
        }
        catch (Exception ex)
        {
            Log($"Optional patch failed for {typeName}.{methodName}: {ex}");
        }
    }

    private static bool HasExternalUpdateVisualsPatch()
    {
        if (_externalUpdateVisualsPatchDetected)
        {
            return true;
        }

        var target = _nCardUpdateVisualsMethod;
        if (target is null)
        {
            return false;
        }

        var now = System.Environment.TickCount64;
        if (now < _nextExternalPatchProbeTicks)
        {
            return false;
        }
        _nextExternalPatchProbeTicks = now + ExternalPatchProbeIntervalMs;

        var patchInfo = HarmonyLib.Harmony.GetPatchInfo(target);
        if (patchInfo is null ||
            (!ContainsExternalPatch(patchInfo.Prefixes) &&
             !ContainsExternalPatch(patchInfo.Postfixes) &&
             !ContainsExternalPatch(patchInfo.Transpilers) &&
             !ContainsExternalPatch(patchInfo.Finalizers)))
        {
            return false;
        }

        _externalUpdateVisualsPatchDetected = true;
        Log("External NCard.UpdateVisuals patch detected; provider capture enabled.");
        return true;
    }

    private static bool ContainsExternalPatch(IEnumerable<Patch> patches)
    {
        foreach (var patch in patches)
        {
            if (!string.Equals(patch.owner, HarmonyId, StringComparison.Ordinal))
            {
                return true;
            }
        }
        return false;
    }

    internal static void OnInspectCardScreenReady(NInspectCardScreen screen)
    {
        try
        {
            Log($"Inspect screen ready: {screen?.Name}");
            if (screen is null || !GodotObject.IsInstanceValid(screen))
            {
                return;
            }

            var manager = TryEnsureManager();
            if (manager is null)
            {
                Log("Manager was not available during inspect screen ready.");
                return;
            }

            RefreshInspectCardProvider(screen);
            AttachOverlay(screen);
        }
        catch (Exception ex)
        {
            Log("OnInspectCardScreenReady failed: " + ex);
        }
    }

    private static Node? TryEnsureManager()
    {
        var tree = Engine.GetMainLoop() as SceneTree;
        var root = tree?.Root;
        if (root is null)
        {
            Log("SceneTree root unavailable.");
            return null;
        }

        var existing = root.GetNodeOrNull<Node>(ManagerNodeName);
        if (existing is not null)
        {
            _pendingManager = existing;
            ConfigureManagerRefreshMode(existing);
            ConfigureSkinChangerBridge(existing);
            return existing;
        }

        if (_pendingManager is not null && GodotObject.IsInstanceValid(_pendingManager))
        {
            ConfigureManagerRefreshMode(_pendingManager);
            ConfigureSkinChangerBridge(_pendingManager);
            return _pendingManager;
        }

        var script = ResourceLoader.Load(ManagerScriptPath) as GDScript;
        if (script is null)
        {
            if (!_loggedManagerLoadFailure)
            {
                Log($"Failed to load manager script at '{ManagerScriptPath}'.");
                _loggedManagerLoadFailure = true;
            }
            return null;
        }

        var manager = script.New().AsGodotObject() as Node;
        if (manager is null)
        {
            if (!_loggedManagerInstantiateFailure)
            {
                Log("Manager script did not instantiate a Node.");
                _loggedManagerInstantiateFailure = true;
            }
            return null;
        }

        _loggedManagerLoadFailure = false;
        _loggedManagerInstantiateFailure = false;
        manager.Name = ManagerNodeName;
        _pendingManager = manager;
        ConfigureManagerRefreshMode(manager);
        ConfigureSkinChangerBridge(manager, true);
        root.CallDeferred(Node.MethodName.AddChild, manager);
        Log("Manager node queued for add to /root.");
        return manager;
    }

    private static void ConfigureManagerRefreshMode(Node manager)
    {
        var configured = manager.GetMeta(ManagerRefreshModeMeta, false).AsBool();
        if (configured == _eventDrivenPortraitRefreshEnabled)
        {
            return;
        }

        manager.Call("set_event_driven_portrait_refresh_enabled", _eventDrivenPortraitRefreshEnabled);
        manager.SetMeta(ManagerRefreshModeMeta, _eventDrivenPortraitRefreshEnabled);
    }

    private static void ConfigureSkinChangerBridge(Node manager, bool forceProbe = false)
    {
        if (manager is null || !GodotObject.IsInstanceValid(manager))
        {
            return;
        }

        if (string.IsNullOrEmpty(_skinChangerRoot))
        {
            var now = System.Environment.TickCount64;
            if (!forceProbe && now < _nextSkinChangerProbeTicks)
            {
                return;
            }
            _nextSkinChangerProbeTicks = now + SkinChangerProbeIntervalMs;
            _skinChangerRoot = ResolveLoadedModRoot(SkinChangerAssemblyName, "Gurio.SkinChanger.dll");
            _cardArtEditorRoot = ResolveLoadedModRoot(typeof(Bootstrap).Assembly.GetName().Name ?? string.Empty, "card_art_editor.dll");
        }

        manager.SetMeta(SkinBridgeRuntimeCheckMeta, true);
        manager.SetMeta(SkinBridgeCaeRootMeta, _cardArtEditorRoot);
        if (string.IsNullOrEmpty(_skinChangerRoot) || !manager.HasMethod("configure_skin_changer_bridge"))
        {
            return;
        }
        if (!InstallSkinChangerOwnershipHooks())
        {
            return;
        }
        manager.SetMeta(SkinBridgeSkinRootMeta, _skinChangerRoot);
        _skinChangerOwnsVisuals = manager.Call("configure_skin_changer_bridge", _skinChangerRoot, _cardArtEditorRoot).AsBool();
        ConnectSkinChangerBridgeSignal(manager);
        TryRefreshSkinChangerCatalog(manager);
    }

    private static void PrepareSkinChangerStartup()
    {
        try
        {
            // All mod assemblies are loaded here, before Skin Changer scans packs.
            var manager = TryEnsureManager();
            if (manager is null)
            {
                return;
            }
            ConfigureSkinChangerBridge(manager, true);
            if (!_skinChangerOwnsVisuals)
            {
                return;
            }
            var assembly = AppDomain.CurrentDomain.GetAssemblies().First(candidate =>
                candidate.GetName().Name == SkinChangerAssemblyName);
            SkinChangerStartupBridge.Install(Harmony, assembly, ProjectSettings.GlobalizePath("user://card_art_editor"));
            Log("Skin Changer startup pack filtering installed before asset initialization.");
        }
        catch (Exception ex)
        {
            Log("Skin Changer startup optimization unavailable; keeping normal bridge refresh: " + ex);
        }
    }

    private static void ConnectSkinChangerBridgeSignal(Node manager)
    {
        if (manager.GetMeta(SkinBridgeSignalConnectedMeta, false).AsBool() || !manager.HasSignal(SkinBridgePackPublishedSignal))
        {
            return;
        }

        if (!_skinChangerPackPublishedCallableReady)
        {
            _skinChangerPackPublishedCallable = Callable.From<string>(OnSkinChangerPackPublished);
            _skinChangerPackPublishedCallableReady = true;
        }

        var error = manager.Connect(SkinBridgePackPublishedSignal, _skinChangerPackPublishedCallable);
        if (error == Error.Ok || error == Error.AlreadyExists)
        {
            manager.SetMeta(SkinBridgeSignalConnectedMeta, true);
        }
        else
        {
            Log($"Skin Changer bridge signal connection failed: {error}.");
        }
    }

    private static void OnSkinChangerPackPublished(string packDirectory)
    {
        _pendingSkinChangerPackDirectory = packDirectory;
        if (_pendingManager is not null && GodotObject.IsInstanceValid(_pendingManager))
        {
            if (_pendingManager.HasMethod("get_skin_changer_bridge_changed_sources_csv"))
            {
                var changedSources = _pendingManager.Call("get_skin_changer_bridge_changed_sources_csv").AsString();
                foreach (var source in changedSources.Split(';', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
                {
                    PendingSkinChangerChangedSources.Add(source);
                }
            }

        }
        _nextSkinChangerCatalogRefreshTicks = 0;
        TryRefreshSkinChangerCatalog(_pendingManager);
    }

    private static void TryRefreshSkinChangerCatalog(Node? manager)
    {
        if (_skinChangerCatalogRefreshActive || string.IsNullOrWhiteSpace(_pendingSkinChangerPackDirectory))
        {
            return;
        }

        var now = System.Environment.TickCount64;
        if (now < _nextSkinChangerCatalogRefreshTicks)
        {
            return;
        }
        _nextSkinChangerCatalogRefreshTicks = now + SkinChangerProbeIntervalMs;

        var skinChangerAssembly = AppDomain.CurrentDomain.GetAssemblies().FirstOrDefault(assembly =>
            string.Equals(assembly.GetName().Name, SkinChangerAssemblyName, StringComparison.OrdinalIgnoreCase));
        if (skinChangerAssembly is null)
        {
            return;
        }

        _skinChangerCatalogRefreshActive = true;
        try
        {
            const BindingFlags flags = BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic;
            var service = skinChangerAssembly.GetType("STS2SkinChanger.Core.SkinService", true)!;
            if (service.GetField("_cardGroupsInitialized", flags)?.GetValue(null) is not true)
            {
                return;
            }
            var catalog = service.GetProperty("Catalog", flags)?.GetValue(null);
            var imports = GetSkinChangerImportedPaths();
            if (catalog is not null && PendingSkinChangerChangedSources.Count == 0 &&
                SkinChangerStartupBridge.IsPublished(catalog, _pendingSkinChangerPackDirectory, imports))
            {
                _pendingSkinChangerPackDirectory = string.Empty;
                Log("Skin Changer unified pack already loaded; skipped duplicate startup refresh.");
                return;
            }
            RefreshSkinChangerCardArtPack(
                skinChangerAssembly,
                _pendingSkinChangerPackDirectory,
                PendingSkinChangerChangedSources);
            var refreshedDirectory = _pendingSkinChangerPackDirectory;
            _pendingSkinChangerPackDirectory = string.Empty;
            PendingSkinChangerChangedSources.Clear();
            _lastSkinChangerCatalogRefreshError = string.Empty;
            Log($"Skin Changer catalog refreshed for unified Card Art Editor pack: {refreshedDirectory}");
            if (manager is not null && GodotObject.IsInstanceValid(manager))
            {
                manager.Call("refresh_all_portraits");
            }
            RefreshVisibleCardsAfterSkinChangerCatalogUpdate();
        }
        catch (Exception ex)
        {
            var message = ex.GetBaseException().Message;
            if (!string.Equals(_lastSkinChangerCatalogRefreshError, message, StringComparison.Ordinal))
            {
                _lastSkinChangerCatalogRefreshError = message;
                Log("Skin Changer catalog refresh deferred: " + ex);
            }
        }
        finally
        {
            _skinChangerCatalogRefreshActive = false;
        }
    }

    private static void RefreshSkinChangerCardArtPack(
        Assembly skinChangerAssembly,
        string packDirectory,
        IEnumerable<string> changedSources)
    {
        const BindingFlags allStatic = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static;
        const BindingFlags allInstance = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance;
        var skinService = skinChangerAssembly.GetType("STS2SkinChanger.Core.SkinService", throwOnError: true)!;
        var catalog = skinService.GetProperty("Catalog", allStatic)?.GetValue(null)
            ?? throw new InvalidOperationException("Skin Changer card catalog is not initialized yet.");
        var catalogType = catalog.GetType();
        var buildEntries = skinService.GetMethod("BuildCardCatalogEntries", allStatic)
            ?? throw new MissingMethodException(skinService.FullName, "BuildCardCatalogEntries");
        var cardEntries = buildEntries.Invoke(null, new object?[] { ModelDb.AllCards })
            ?? throw new InvalidOperationException("Skin Changer did not build card catalog entries.");

        var affectedGroups = RemoveSkinChangerPackOptions(catalog, catalogType, SkinBridgePackId);
        var importedPaths = GetSkinChangerImportedPaths();
        var releasedPaths = SkinChangerStartupBridge.UpdateImportedPaths(importedPaths);
        affectedGroups.UnionWith(SkinChangerCatalogBridge.FilterImportedPacks(catalog, importedPaths));
        object? attachResult = null;
        var scannerType = skinChangerAssembly.GetType("STS2SkinChanger.Catalog.CardArtPackScanner", throwOnError: true)!;
        var scan = scannerType.GetMethod("Scan", BindingFlags.Public | BindingFlags.Static)
            ?? throw new MissingMethodException(scannerType.FullName, "Scan");
        // A pack skipped at startup may become independent again when unregistered.
        var roots = releasedPaths.Select(Path.GetDirectoryName).OfType<string>().Append(packDirectory).Distinct().ToArray();
        var scanResult = scan.Invoke(null, new object?[] { roots })
            ?? throw new InvalidOperationException("Skin Changer did not return an art pack scan result.");
        var packs = scanResult.GetType().GetProperty("Packs", allInstance)?.GetValue(scanResult)
            ?? throw new InvalidOperationException("Skin Changer art pack scan did not expose packs.");
        if (EnumerableHasItems(packs))
        {
            var attach = catalogType.GetMethod("AttachCardArtPacks", allInstance)
                ?? throw new MissingMethodException(catalogType.FullName, "AttachCardArtPacks");
            attachResult = attach.Invoke(catalog, new[] { packs, cardEntries });
        }
        SkinChangerCatalogBridge.ConfigurePresentations(catalog, (IEnumerable)cardEntries, (IEnumerable)packs);

        var finalize = catalogType.GetMethod("FinalizeCardGroups", allInstance)
            ?? throw new MissingMethodException(catalogType.FullName, "FinalizeCardGroups");
        finalize.Invoke(catalog, new[] { cardEntries });
        var currentGroups = FindSkinChangerPackGroups(catalog, SkinBridgePackId);
        affectedGroups.UnionWith(currentGroups);
        foreach (var pack in (IEnumerable)packs)
        {
            if (pack.GetType().GetProperty("Id")?.GetValue(pack) is string id)
            {
                affectedGroups.UnionWith(FindSkinChangerPackGroups(catalog, id));
            }
        }
        SanitizeSkinChangerSelections(skinService);
        ClearSkinChangerRuntimeCaches(skinService, affectedGroups);
        InvalidateSkinChangerPackResources(skinService);
        ResetSkinChangerCardCaches(skinService);
        RegisterSkinChangerPackCoverage(skinChangerAssembly, attachResult);

        var changedCards = ResolveSkinChangerCards(changedSources);
        ApplySkinChangerPackSelections(skinService, currentGroups, changedCards);
        SkinChangerStartupBridge.MarkPublished(catalog, packDirectory);
        Log($"Skin Changer bridge groups={string.Join(",", currentGroups)}; imported pack sources={importedPaths.Length}; full-art and filter groups configured.");
    }

    private static string[] GetSkinChangerImportedPaths() =>
        _pendingManager is not null && GodotObject.IsInstanceValid(_pendingManager)
            ? _pendingManager.Call("get_skin_changer_bridge_imported_pack_paths").AsStringArray()
            : Array.Empty<string>();


    private static HashSet<string> RemoveSkinChangerPackOptions(object catalog, Type catalogType, string packId)
    {
        const BindingFlags allInstance = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance;
        var result = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var field = catalogType.GetField("_artPackCardGroups", allInstance);
        if (field?.GetValue(catalog) is not IDictionary groups)
        {
            throw new InvalidOperationException("Skin Changer art pack groups are unavailable.");
        }

        foreach (DictionaryEntry pair in groups)
        {
            var group = pair.Value;
            if (group is null)
            {
                continue;
            }
            var options = group.GetType().GetProperty("Options", allInstance)?.GetValue(group) as IList;
            if (options is null)
            {
                continue;
            }
            var removed = false;
            for (var index = options.Count - 1; index >= 0; index--)
            {
                var option = options[index];
                var optionId = option?.GetType().GetProperty("Id", allInstance)?.GetValue(option) as string;
                if (!string.Equals(optionId, packId, StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }
                options.RemoveAt(index);
                removed = true;
            }
            if (removed && pair.Key is string groupId)
            {
                result.Add(groupId);
            }
        }
        return result;
    }

    private static HashSet<string> FindSkinChangerPackGroups(object catalog, string packId)
    {
        const BindingFlags allInstance = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance;
        var result = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var groups = catalog.GetType().GetProperty("CardGroups", allInstance)?.GetValue(catalog) as IEnumerable;
        if (groups is null)
        {
            return result;
        }
        foreach (var group in groups)
        {
            if (group is null)
            {
                continue;
            }
            var groupType = group.GetType();
            var groupId = groupType.GetProperty("Id", allInstance)?.GetValue(group) as string;
            var options = groupType.GetProperty("Options", allInstance)?.GetValue(group) as IEnumerable;
            if (string.IsNullOrWhiteSpace(groupId) || options is null)
            {
                continue;
            }
            foreach (var option in options)
            {
                var optionId = option?.GetType().GetProperty("Id", allInstance)?.GetValue(option) as string;
                if (string.Equals(optionId, packId, StringComparison.OrdinalIgnoreCase))
                {
                    result.Add(groupId);
                    break;
                }
            }
        }
        return result;
    }

    private static List<CardModel> ResolveSkinChangerCards(IEnumerable<string> sourcePaths)
    {
        var normalizedSources = sourcePaths
            .Select(NormalizeCardSourcePath)
            .Where(path => !string.IsNullOrEmpty(path))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();
        if (normalizedSources.Length == 0)
        {
            return new List<CardModel>();
        }

        var candidates = ModelDb.AllCards
            .Select(card => (Card: card, Path: NormalizeCardSourcePath(GetPreferredPortraitPath(card))))
            .ToArray();
        var matches = new HashSet<CardModel>();
        foreach (var source in normalizedSources)
        {
            var exactMatches = candidates.Where(candidate =>
                string.Equals(candidate.Path, source, StringComparison.OrdinalIgnoreCase)).ToArray();
            if (exactMatches.Length > 0)
            {
                foreach (var match in exactMatches)
                {
                    matches.Add(match.Card);
                }
                continue;
            }

            // Modded portrait paths are not always canonical. A filename fallback is
            // safe only when it identifies exactly one model.
            var stem = GetCardSourceStem(source);
            var stemMatches = candidates.Where(candidate =>
                string.Equals(GetCardSourceStem(candidate.Path), stem, StringComparison.OrdinalIgnoreCase)).ToArray();
            if (stemMatches.Length == 1)
            {
                matches.Add(stemMatches[0].Card);
            }
        }
        return matches.ToList();
    }

    private static string NormalizeCardSourcePath(string path)
    {
        var normalized = (path ?? string.Empty).Trim().Replace('\\', '/').ToLowerInvariant();
        const string atlasPrefix = "res://images/atlases/card_atlas.sprites/";
        if (normalized.StartsWith(atlasPrefix, StringComparison.Ordinal))
        {
            normalized = "res://images/packed/card_portraits/" + normalized[atlasPrefix.Length..];
        }
        var extensionIndex = normalized.LastIndexOf('.');
        if (extensionIndex > normalized.LastIndexOf('/'))
        {
            normalized = normalized[..extensionIndex] + ".png";
        }
        return normalized;
    }

    private static string GetCardSourceStem(string path)
    {
        return Path.GetFileNameWithoutExtension(path ?? string.Empty).ToLowerInvariant();
    }

    private static void ApplySkinChangerPackSelections(
        Type skinService,
        HashSet<string> currentGroups,
        IEnumerable<CardModel> changedCards)
    {
        const BindingFlags allStatic = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static;
        var setEnabled = skinService.GetMethod("SetCardPriorityEnabled", allStatic);
        var getGroupId = skinService.GetMethod("GetCardCatalogGroupId", allStatic);
        var getFilterGroupId = skinService.GetMethod("GetCardFilterGroupId", allStatic);
        var movePriority = skinService.GetMethod("MoveCardPriority", allStatic);
        var applyCardSelection = skinService.GetMethods(allStatic).FirstOrDefault(method =>
            method.Name == "ApplyCardSelection" &&
            method.GetParameters().Length == 2 &&
            typeof(CardModel).IsAssignableFrom(method.GetParameters()[0].ParameterType));
        if (setEnabled is null || applyCardSelection is null)
        {
            throw new MissingMethodException("Skin Changer card selection API is unavailable.");
        }

        // A stale per-card choice wins over its category in Skin Changer. Only cards
        // whose CAE entry changed are returned to category inheritance here.
        var editedGroups = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var card in changedCards)
        {
            // Restoring a card only removes CAE's entry. Do not erase a user's
            // explicit choice of a different provider or re-enable CAE on restore.
            var source = GetPreferredPortraitPath(card);
            if (_pendingManager is not null && GodotObject.IsInstanceValid(_pendingManager) &&
                _pendingManager.Call("has_override", source).AsBool())
            {
                if (applyCardSelection.Invoke(null, new object?[] { card, "__inherit__" }) is not true)
                {
                    throw new InvalidOperationException($"Skin Changer could not select edited card {card.Id}: " +
                        skinService.GetProperty("LastError", allStatic)?.GetValue(null));
                }
                if (getGroupId?.Invoke(null, new object?[] { card }) is string groupId && currentGroups.Contains(groupId))
                {
                    editedGroups.Add(groupId);
                }
                if (getFilterGroupId?.Invoke(null, new object?[] { card }) is string filterId && currentGroups.Contains(filterId))
                {
                    editedGroups.Add(filterId);
                }
            }
        }

        foreach (var groupId in editedGroups)
        {
            setEnabled.Invoke(null, new object?[] { groupId, SkinBridgePackId, true });
            movePriority?.Invoke(null, new object?[] { groupId, SkinBridgePackId, -1024 });
        }
    }

    private static bool InstallSkinChangerOwnershipHooks()
    {
        if (_skinChangerOwnershipHooksInstalled)
        {
            return true;
        }
        var assembly = AppDomain.CurrentDomain.GetAssemblies().FirstOrDefault(candidate =>
            string.Equals(candidate.GetName().Name, SkinChangerAssemblyName, StringComparison.OrdinalIgnoreCase));
        var bridge = assembly?.GetType("STS2SkinChanger.Core.ExternalCardVisualBridge");
        const BindingFlags flags = BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic;
        var ownership = bridge?.GetMethod("GetScriptedManagerOwnership", flags);
        var synchronize = bridge?.GetMethod("SynchronizeProvider", flags);
        if (ownership is null || synchronize is null)
        {
            return false;
        }

        // Disable only Skin Changer's callback into THIS scripted manager, not
        // ownership reported by other mods. A skipped struct result is default.
        var prefix = new HarmonyMethod(typeof(Bootstrap), nameof(AllowSkinChangerEditorCallback));
        Harmony.Patch(ownership, prefix: prefix);
        Harmony.Patch(synchronize, prefix: prefix);
        _skinChangerOwnershipHooksInstalled = true;
        Log("Skin Changer visual ownership handoff installed.");
        return true;
    }

    private static bool AllowSkinChangerEditorCallback()
    {
        return !_skinChangerOwnsVisuals;
    }

    private static void InvalidateSkinChangerPackResources(Type skinService)
    {
        const BindingFlags flags = BindingFlags.Static | BindingFlags.NonPublic;
        // Clearing decoded textures alone is insufficient: these aliases still
        // point at the old bytes after a pack is edited in the same session.
        if (skinService.GetField("IsolatedCardOverlayCache", flags)?.GetValue(null) is not IDictionary cache)
        {
            throw new MissingFieldException(skinService.FullName, "IsolatedCardOverlayCache");
        }
        var staleKeys = cache.Keys.Cast<object>().OfType<string>()
            .Where(key => key.Split('\n').ElementAtOrDefault(1) == SkinBridgePackId).ToArray();
        foreach (var key in staleKeys)
        {
            cache.Remove(key);
        }
    }

    private static void SanitizeSkinChangerSelections(Type skinService)
    {
        const BindingFlags allStatic = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static;
        skinService.GetMethod("SanitizeCardSelections", allStatic, null, Type.EmptyTypes, null)?.Invoke(null, null);
    }

    private static void RegisterSkinChangerPackCoverage(Assembly skinChangerAssembly, object? attachResult)
    {
        if (attachResult is null)
        {
            return;
        }
        var coveredTypes = attachResult.GetType().GetField("Item1")?.GetValue(attachResult);
        if (coveredTypes is null)
        {
            return;
        }
        var bridgeType = skinChangerAssembly.GetType("STS2SkinChanger.Core.ExternalCardVisualBridge");
        bridgeType?.GetMethod("RegisterArtPackCoverage", BindingFlags.Public | BindingFlags.Static)?.Invoke(null, new[] { coveredTypes });
    }

    private static void ResetSkinChangerCardCaches(Type skinService)
    {
        const BindingFlags allStatic = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static;
        var lookup = skinService.GetField("_cardLookupCache", allStatic);
        if (lookup is not null)
        {
            lookup.SetValue(null, Activator.CreateInstance(lookup.FieldType));
        }
        var coverage = skinService.GetField("CardCoverageCache", allStatic)?.GetValue(null);
        coverage?.GetType().GetMethod("Clear", Type.EmptyTypes)?.Invoke(coverage, null);
        var failedRequests = skinService.GetField("FailedCardPortraitRequests", allStatic)?.GetValue(null);
        failedRequests?.GetType().GetMethod("Clear", Type.EmptyTypes)?.Invoke(failedRequests, null);
    }

    private static void ClearSkinChangerRuntimeCaches(Type skinService, IEnumerable<string> groupIds)
    {
        const BindingFlags allStatic = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static;
        var clearPortraits = skinService.GetMethod("ClearCardPortraitCache", allStatic, null, new[] { typeof(string) }, null);
        var clearRuntimeResources = skinService.GetMethod("ClearRuntimeResourceCache", allStatic, null, new[] { typeof(string) }, null);
        foreach (var groupId in groupIds.Distinct(StringComparer.OrdinalIgnoreCase))
        {
            clearPortraits?.Invoke(null, new object?[] { groupId });
            clearRuntimeResources?.Invoke(null, new object?[] { groupId });
        }
    }


    private static bool EnumerableHasItems(object value)
    {
        if (value is not IEnumerable enumerable)
        {
            return false;
        }
        var enumerator = enumerable.GetEnumerator();
        try
        {
            return enumerator.MoveNext();
        }
        finally
        {
            (enumerator as IDisposable)?.Dispose();
        }
    }

    private static void RefreshVisibleCardsAfterSkinChangerCatalogUpdate()
    {
        var root = (Engine.GetMainLoop() as SceneTree)?.Root;
        if (root is null)
        {
            return;
        }
        var pending = new Stack<Node>();
        pending.Push(root);
        var visited = 0;
        while (pending.Count > 0 && visited < 8192)
        {
            var node = pending.Pop();
            visited++;
            if (!GodotObject.IsInstanceValid(node))
            {
                continue;
            }
            if (node is NCard card && card.IsVisibleInTree())
            {
                ClearCachedPortraitPath(card);
                try
                {
                    NCardReloadMethod?.Invoke(card, null);
                }
                catch (Exception ex)
                {
                    Log("Visible card refresh after Skin Changer update failed: " + ex.GetBaseException().Message);
                }
            }
            foreach (var child in node.GetChildren())
            {
                pending.Push(child);
            }
        }
    }

    private static string ResolveLoadedModRoot(string assemblyName, string expectedFileName)
    {
        if (string.IsNullOrWhiteSpace(assemblyName))
        {
            return string.Empty;
        }

        foreach (var assembly in AppDomain.CurrentDomain.GetAssemblies())
        {
            try
            {
                if (!string.Equals(assembly.GetName().Name, assemblyName, StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }
                var location = assembly.Location;
                if (string.IsNullOrWhiteSpace(location) || !File.Exists(location))
                {
                    continue;
                }
                if (!string.Equals(Path.GetFileName(location), expectedFileName, StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }
                return Path.GetDirectoryName(location) ?? string.Empty;
            }
            catch
            {
            }
        }
        return string.Empty;
    }

    private static void TryAttachToOpenInspectScreens()
    {
        var tree = Engine.GetMainLoop() as SceneTree;
        var root = tree?.Root;
        if (root is null)
        {
            return;
        }

        foreach (var child in root.GetChildren())
        {
            ScanNode(child);
        }
    }

    private static void ScanNode(Node node)
    {
        if (node is NInspectCardScreen inspectScreen)
        {
            OnInspectCardScreenReady(inspectScreen);
        }

        foreach (var child in node.GetChildren())
        {
            if (child is Node childNode)
            {
                ScanNode(childNode);
            }
        }
    }

    private static void AttachOverlay(Control screen)
    {
        if (screen.GetNodeOrNull<Node>("CardArtEditorOverlay") is not null)
        {
            Log("Overlay already attached.");
            return;
        }

        var overlayScene = ResourceLoader.Load(OverlayScenePath) as PackedScene;
        if (overlayScene is null)
        {
            if (!_loggedOverlayLoadFailure)
            {
                Log($"Failed to load overlay scene at '{OverlayScenePath}'.");
                _loggedOverlayLoadFailure = true;
            }
            return;
        }

        _loggedOverlayLoadFailure = false;
        var overlay = overlayScene.Instantiate<Control>();
        overlay.Name = "CardArtEditorOverlay";
        screen.AddChild(overlay);
        var overlayScript = overlay.GetScript();
        var overlayScriptText = overlayScript.VariantType == Variant.Type.Nil ? "<null>" : overlayScript.ToString();
        var button = overlay.GetNodeOrNull<Button>("EditArtButton");
        var popup = overlay.GetNodeOrNull<Control>("EditorPopup");
        Log(
            "Overlay attached. " +
            $"overlay_type={overlay.GetType().FullName}, " +
            $"script={overlayScriptText}, " +
            $"has_edit_method={overlay.HasMethod("_on_edit_art_pressed")}, " +
            $"has_open_method={overlay.HasMethod("_open_editor_popup")}, " +
            $"button_exists={button is not null}, " +
            $"popup_exists={popup is not null}"
        );

        if (button is not null)
        {
            Log(
                "EditArtButton state: " +
                $"visible={button.Visible}, disabled={button.Disabled}, " +
                $"position={button.Position}, size={button.Size}, mouse_filter={(int)button.MouseFilter}"
            );
            button.Pressed += () =>
            {
                var currentPopup = overlay.GetNodeOrNull<Control>("EditorPopup");
                Log(
                    "EditArtButton pressed from bootstrap. " +
                    $"overlay_has_method={overlay.HasMethod("_on_edit_art_pressed")}, " +
                    $"popup_exists={currentPopup is not null}, " +
                    $"popup_visible_before={(currentPopup is null ? "<null>" : currentPopup.Visible.ToString())}"
                );
            };
        }
    }

    private static void Log(string message)
    {
        try
        {
            var directory = ProjectSettings.GlobalizePath("user://card_art_editor");
            Directory.CreateDirectory(directory);
            var logPath = Path.Combine(directory, "bootstrap.log");
            File.AppendAllText(logPath, $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {message}{System.Environment.NewLine}");
        }
        catch
        {
        }
    }

    internal static void UpdateInspectCardMetadata(NInspectCardScreen screen)
    {
        try
        {
            if (screen is null || !GodotObject.IsInstanceValid(screen))
            {
                return;
            }

            var card = Traverse.Create(screen).Field("_card").GetValue<NCard>();
            if (card is null || !GodotObject.IsInstanceValid(card))
            {
                screen.SetMeta(InspectCardNodePathMeta, string.Empty);
                screen.SetMeta(InspectSourcePathMeta, string.Empty);
                screen.SetMeta(InspectCardIdMeta, string.Empty);
                screen.SetMeta(InspectBaseGameModelMeta, false);
                screen.SetMeta(InspectModelOwnerMeta, string.Empty);
                return;
            }

            screen.SetMeta(InspectCardNodePathMeta, screen.GetPathTo(card).ToString());

            if (!TryGetCardModel(card, out var model) || model is null)
            {
                ClearCachedPortraitPath(card);
                card.SetMeta(InspectSourcePathMeta, string.Empty);
                card.SetMeta(InspectCardIdMeta, string.Empty);
                card.SetMeta(InspectBaseGameModelMeta, false);
                card.SetMeta(InspectModelOwnerMeta, string.Empty);
                screen.SetMeta(InspectSourcePathMeta, string.Empty);
                screen.SetMeta(InspectCardIdMeta, string.Empty);
                screen.SetMeta(InspectBaseGameModelMeta, false);
                screen.SetMeta(InspectModelOwnerMeta, string.Empty);
                return;
            }

            var cardId = GetCardId(model);
            ClearCachedPortraitPath(card);
            var sourcePath = GetCachedPortraitPath(card, model, cardId);
            card.SetMeta(InspectSourcePathMeta, sourcePath);
            card.SetMeta(InspectCardIdMeta, cardId);
            StampCardModelOwnership(card, model);
            RegisterCardProviderSource(model, sourcePath, cardId);
            screen.SetMeta(InspectSourcePathMeta, sourcePath);
            screen.SetMeta(InspectCardIdMeta, cardId);
            screen.SetMeta(InspectBaseGameModelMeta, card.GetMeta(InspectBaseGameModelMeta));
            screen.SetMeta(InspectModelOwnerMeta, card.GetMeta(InspectModelOwnerMeta));

            var diagnostic = $"{card.GetInstanceId()}|{cardId}|{sourcePath}|{model.GetType().AssemblyQualifiedName}";
            if (!string.Equals(_lastInspectMetadataDiagnostic, diagnostic, StringComparison.Ordinal))
            {
                _lastInspectMetadataDiagnostic = diagnostic;
                Log($"Inspect metadata: card_path='{screen.GetPathTo(card)}', card_id='{cardId}', source='{sourcePath}', model='{model.GetType().FullName}', base_game={card.GetMeta(InspectBaseGameModelMeta)}");
            }
        }
        catch (Exception ex)
        {
            Log("UpdateInspectCardMetadata failed: " + ex);
        }
    }

    internal static void RefreshCardOverrides(NCard card)
    {
        TryReloadBrokenNativeAncientLayout(card);
        UpdateInspectCardMetadataFromCard(card);
        QueueCardOverrideRefresh(card);
    }

    internal static void RefreshInspectCardProvider(NInspectCardScreen screen)
    {
        UpdateInspectCardMetadata(screen);
        if (!HasExternalUpdateVisualsPatch())
        {
            return;
        }

        try
        {
            var card = Traverse.Create(screen).Field("_card").GetValue<NCard>();
            if (card is null || !GodotObject.IsInstanceValid(card))
            {
                return;
            }

            CaptureCardProviderPostfix(card);
            var manager = TryEnsureManager();
            manager?.Call("register_inspect_card_provider_pin", card);
        }
        catch (Exception ex)
        {
            Log("RefreshInspectCardProvider failed: " + ex);
        }
    }

    internal static void UnregisterInspectCardProvider(NInspectCardScreen screen)
    {
        try
        {
            var card = Traverse.Create(screen).Field("_card").GetValue<NCard>();
            if (card is null || !GodotObject.IsInstanceValid(card))
            {
                return;
            }

            var manager = TryEnsureManager();
            manager?.Call("unregister_inspect_card_provider_pin", card);
        }
        catch (Exception ex)
        {
            Log("UnregisterInspectCardProvider failed: " + ex);
        }
    }

    private static void TrySuppressSpecialCardEffects(NCard card)
    {
        try
        {
            if (!TryGetCardModel(card, out var model) || model is null)
            {
                return;
            }

            var cardId = model.Id.Entry ?? string.Empty;
            var typeName = model.GetType().Name ?? string.Empty;
            if (!string.Equals(cardId, "INFECTION", StringComparison.OrdinalIgnoreCase) &&
                !string.Equals(typeName, "Infection", StringComparison.OrdinalIgnoreCase))
            {
                return;
            }

            var suppressionEnabled = true;
            var manager = TryEnsureManager();
            if (manager is not null)
            {
                suppressionEnabled = manager.Call("is_infection_effect_hidden_enabled").AsBool();
            }

            ApplyInfectionEffectNodeVisibility(card, suppressionEnabled);
        }
        catch (Exception ex)
        {
            Log("TrySuppressSpecialCardEffects failed: " + ex);
        }
    }

    private static bool TryGetCardModel(NCard card, out CardModel? model, bool logFailures = true)
    {
        model = null;
        try
        {
            model = card.Model;
            return model is not null;
        }
        catch (ModelNotFoundException ex)
        {
            if (logFailures)
            {
                Log($"Skipping card '{card?.Name}' because model lookup failed: {ex.Message}");
            }
            return false;
        }
        catch (Exception ex)
        {
            if (logFailures)
            {
                Log($"Unexpected card model lookup failure for '{card?.Name}': {ex}");
            }
            return false;
        }
    }

    private static string GetCardId(CardModel model)
    {
        return model.Id.Entry ?? string.Empty;
    }

    private static long GetModelCacheKey(CardModel model)
    {
        return RuntimeHelpers.GetHashCode(model);
    }

    private static void ClearCachedPortraitPath(NCard card)
    {
        if (card.HasMeta(CachedPortraitPathMeta))
        {
            card.RemoveMeta(CachedPortraitPathMeta);
        }

        if (card.HasMeta(CachedPortraitCardIdMeta))
        {
            card.RemoveMeta(CachedPortraitCardIdMeta);
        }

        if (card.HasMeta(CachedPortraitModelKeyMeta))
        {
            card.RemoveMeta(CachedPortraitModelKeyMeta);
        }
    }

    private static string GetCachedPortraitPath(NCard card, CardModel model, string cardId)
    {
        var modelKey = GetModelCacheKey(model);
        if (card.HasMeta(CachedPortraitPathMeta) &&
            card.HasMeta(CachedPortraitCardIdMeta) &&
            card.HasMeta(CachedPortraitModelKeyMeta))
        {
            var cachedCardId = card.GetMeta(CachedPortraitCardIdMeta).AsString();
            var cachedModelKey = card.GetMeta(CachedPortraitModelKeyMeta).AsInt64();
            if (string.Equals(cachedCardId, cardId, StringComparison.Ordinal) && cachedModelKey == modelKey)
            {
                return card.GetMeta(CachedPortraitPathMeta).AsString();
            }
        }

        var sourcePath = GetPreferredPortraitPath(model);
        card.SetMeta(CachedPortraitPathMeta, sourcePath);
        card.SetMeta(CachedPortraitCardIdMeta, cardId);
        card.SetMeta(CachedPortraitModelKeyMeta, modelKey);
        return sourcePath;
    }

    private static string GetPreferredPortraitPath(CardModel model)
    {
        var customPortraitPath = TryGetCustomPortraitPath(model);
        if (!string.IsNullOrEmpty(customPortraitPath))
        {
            return customPortraitPath;
        }

        return model.PortraitPath ?? string.Empty;
    }

    private static string TryGetCustomPortraitPath(CardModel model)
    {
        try
        {
            var type = model.GetType();
            if (!CustomPortraitPathPropertyCache.TryGetValue(type, out var property))
            {
                property = type.GetProperty(
                    "CustomPortraitPath",
                    BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance
                );
                CustomPortraitPathPropertyCache[type] = property;
            }

            if (property is null || property.PropertyType != typeof(string))
            {
                return string.Empty;
            }

            return property.GetValue(model) as string ?? string.Empty;
        }
        catch
        {
            return string.Empty;
        }
    }

    private static CanvasItem? FindCanvasItemByName(Node root, string nodeName, ref int visited)
    {
        if (!GodotObject.IsInstanceValid(root) || visited >= 128)
        {
            return null;
        }

        visited++;
        if (root is CanvasItem canvasItem && string.Equals(root.Name.ToString(), nodeName, StringComparison.Ordinal))
        {
            return canvasItem;
        }

        foreach (var child in root.GetChildren())
        {
            if (child is not Node childNode)
            {
                continue;
            }

            var match = FindCanvasItemByName(childNode, nodeName, ref visited);
            if (match is not null)
            {
                return match;
            }
        }

        return null;
    }

    private static CanvasItem? FindCanvasItemByName(Node root, string nodeName)
    {
        var visited = 0;
        return FindCanvasItemByName(root, nodeName, ref visited);
    }

    private static bool TryReloadBrokenNativeAncientLayout(NCard card)
    {
        if (_skinChangerOwnsVisuals)
        {
            return false;
        }
        try
        {
            if (card is null || !GodotObject.IsInstanceValid(card) ||
                card.HasMeta(NativeAncientLayoutReloadingMeta) ||
                !TryGetCardModel(card, out var model, logFailures: false) || model is null ||
                (int)model.Rarity != AncientCardRarityValue)
            {
                return false;
            }

            var portrait = FindCanvasItemByName(card, "Portrait");
            var frame = FindCanvasItemByName(card, "Frame");
            var ancientPortrait = FindCanvasItemByName(card, "AncientPortrait");
            var ancientBorder = FindCanvasItemByName(card, "AncientBorder");
            var layoutIsBroken =
                ancientPortrait is null || !ancientPortrait.Visible ||
                ancientBorder is null || !ancientBorder.Visible ||
                portrait?.Visible == true || frame?.Visible == true;
            if (!layoutIsBroken || NCardReloadMethod is null)
            {
                return false;
            }

            card.SetMeta(NativeAncientLayoutReloadingMeta, true);
            try
            {
                Log($"Reloading broken native Ancient layout: card_id='{GetCardId(model)}', card_path='{DescribeNodePath(card)}'.");
                NCardReloadMethod.Invoke(card, null);
            }
            finally
            {
                if (GodotObject.IsInstanceValid(card) && card.HasMeta(NativeAncientLayoutReloadingMeta))
                {
                    card.RemoveMeta(NativeAncientLayoutReloadingMeta);
                }
            }

            return true;
        }
        catch (Exception ex)
        {
            Log("TryReloadBrokenNativeAncientLayout failed: " + ex);
            return false;
        }
    }

    private static void StampCardModelOwnership(NCard card, CardModel model)
    {
        var modelType = model.GetType();
        var isBaseGameModel = modelType.Assembly == typeof(CardModel).Assembly;
        var assemblyName = modelType.Assembly.GetName().Name ?? string.Empty;
        var modelOwner = $"{assemblyName}:{modelType.FullName ?? modelType.Name}";
        card.SetMeta(InspectBaseGameModelMeta, isBaseGameModel);
        card.SetMeta(InspectModelOwnerMeta, modelOwner);
    }

    private static void RegisterCardProviderSource(CardModel model, string sourcePath, string cardId)
    {
        var manager = TryEnsureManager();
        if (manager is null || _skinChangerOwnsVisuals)
        {
            return;
        }

        var isBaseGameModel = model.GetType().Assembly == typeof(CardModel).Assembly;
        manager.Call("register_runtime_provider_source", sourcePath, cardId, isBaseGameModel);
    }

    private static void UpdateInspectCardMetadataFromCard(NCard card)
    {
        try
        {
            if (card is null || !GodotObject.IsInstanceValid(card))
            {
                return;
            }

            if (!TryGetCardModel(card, out var model) || model is null)
            {
                ClearCachedPortraitPath(card);
                card.SetMeta(InspectSourcePathMeta, string.Empty);
                card.SetMeta(InspectCardIdMeta, string.Empty);
                card.SetMeta(InspectBaseGameModelMeta, false);
                card.SetMeta(InspectModelOwnerMeta, string.Empty);
                card.RemoveMeta(InspectModelRarityMeta);
                return;
            }

            var cardId = GetCardId(model);
            var sourcePath = GetCachedPortraitPath(card, model, cardId);
            card.SetMeta(InspectSourcePathMeta, sourcePath);
            card.SetMeta(InspectCardIdMeta, cardId);
            card.SetMeta(InspectModelRarityMeta, (int)model.Rarity);
            StampCardModelOwnership(card, model);
            RegisterCardProviderSource(model, sourcePath, cardId);
        }
        catch (Exception ex)
        {
            Log("UpdateInspectCardMetadataFromCard failed: " + ex);
        }
    }

    private static void ApplyInfectionEffectNodeVisibility(Node root, bool hide)
    {
        foreach (var child in root.GetChildren())
        {
            if (child is not Node childNode)
            {
                continue;
            }

            var nodeName = childNode.Name?.ToString() ?? string.Empty;
            var lowerName = nodeName.ToLowerInvariant();
            var shouldHideByName =
                lowerName.Contains("infection") ||
                lowerName.Contains("effect") ||
                lowerName.Contains("vfx") ||
                lowerName.Contains("glow") ||
                lowerName.Contains("goo") ||
                lowerName.Contains("worm");

            var typeName = childNode.GetType().Name;
            var shouldHideByType =
                string.Equals(typeName, "GPUParticles2D", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(typeName, "CPUParticles2D", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(typeName, "AnimatedSprite2D", StringComparison.OrdinalIgnoreCase);

            if (shouldHideByName || shouldHideByType)
            {
                if (childNode is CanvasItem canvasItem)
                {
                    if (hide)
                    {
                        if (!childNode.HasMeta(InfectionEffectSuppressedMeta))
                        {
                            childNode.SetMeta(InfectionEffectOriginalVisibleMeta, canvasItem.Visible);
                            childNode.SetMeta(InfectionEffectSuppressedMeta, true);
                        }
                        canvasItem.Visible = false;
                    }
                    else if (childNode.HasMeta(InfectionEffectSuppressedMeta))
                    {
                        var originalVisible = childNode.GetMeta(InfectionEffectOriginalVisibleMeta).AsBool();
                        canvasItem.Visible = originalVisible;
                        childNode.RemoveMeta(InfectionEffectSuppressedMeta);
                        childNode.RemoveMeta(InfectionEffectOriginalVisibleMeta);
                    }
                    else if (!canvasItem.Visible)
                    {
                        canvasItem.Visible = true;
                    }
                }
            }

            ApplyInfectionEffectNodeVisibility(childNode, hide);
        }
    }

    private static void ApplyOverridesToCardPortraitsDeferred(Node manager, NCard card, bool invalidateModelCache = false)
    {
        manager.Call("queue_card_override_refresh", card, invalidateModelCache);
    }

    private static void QueueCardOverrideRefresh(NCard card)
    {
        try
        {
            if (card is null || !GodotObject.IsInstanceValid(card))
            {
                return;
            }

            if (card.HasMeta(DeferredCardRefreshPendingMeta))
            {
                ClearCachedPortraitPath(card);
                card.SetMeta(DeferredCardRefreshInvalidateModelMeta, true);
                return;
            }

            TrySuppressSpecialCardEffects(card);
            ClearCachedPortraitPath(card);
            var manager = TryEnsureManager();
            if (manager is null)
            {
                return;
            }

            ApplyOverridesToCardPortraitsDeferred(manager, card, true);
        }
        catch (Exception ex)
        {
            Log("QueueCardOverrideRefresh failed: " + ex);
        }
    }

    internal static void RefreshCardOverridesAfterGameVisualUpdate(NCard card)
    {
        QueueCardOverrideRefresh(card);
    }

    private static NCard? TryAsValidCard(object? value)
    {
        if (value is NCard card && GodotObject.IsInstanceValid(card))
        {
            return card;
        }

        return null;
    }

    private static NCard? TryFindCardNodeInTree(Node node)
    {
        var visited = 0;
        return TryFindCardNodeInTree(node, ref visited);
    }

    private static NCard? TryFindCardNodeInTree(Node node, ref int visited)
    {
        if (!GodotObject.IsInstanceValid(node) || visited >= 96)
        {
            return null;
        }

        visited++;
        if (node is NCard card && GodotObject.IsInstanceValid(card))
        {
            return card;
        }

        foreach (var child in node.GetChildren())
        {
            if (child is not Node childNode)
            {
                continue;
            }

            var found = TryFindCardNodeInTree(childNode, ref visited);
            if (found is not null)
            {
                return found;
            }
        }

        return null;
    }

    internal static NCard? TryFindCardNode(object? source)
    {
        try
        {
            if (source is null)
            {
                return null;
            }

            var directCard = TryAsValidCard(source);
            if (directCard is not null)
            {
                return directCard;
            }

            var type = source.GetType();
            if (!CardNodeMemberCache.TryGetValue(type, out var member))
            {
                member = ResolveCardNodeMember(type);
                CardNodeMemberCache[type] = member;
            }

            var cardFromMember = TryGetCardFromMember(source, member);
            if (cardFromMember is not null)
            {
                return cardFromMember;
            }

            return source is Node node ? TryFindCardNodeInTree(node) : null;
        }
        catch (Exception ex)
        {
            Log("TryFindCardNode failed: " + ex);
            return null;
        }
    }

    private static MemberInfo? ResolveCardNodeMember(Type type)
    {
        const BindingFlags flags =
            BindingFlags.Public |
            BindingFlags.NonPublic |
            BindingFlags.Instance;

        foreach (var memberName in new[] { "CardNode", "_cardNode", "cardNode", "Card", "_card", "card" })
        {
            var property = type.GetProperty(memberName, flags);
            if (property is not null && property.GetIndexParameters().Length == 0 && typeof(NCard).IsAssignableFrom(property.PropertyType))
            {
                return property;
            }

            var field = type.GetField(memberName, flags);
            if (field is not null && typeof(NCard).IsAssignableFrom(field.FieldType))
            {
                return field;
            }
        }

        foreach (var property in type.GetProperties(flags))
        {
            if (property.GetIndexParameters().Length == 0 && typeof(NCard).IsAssignableFrom(property.PropertyType))
            {
                return property;
            }
        }

        foreach (var field in type.GetFields(flags))
        {
            if (typeof(NCard).IsAssignableFrom(field.FieldType))
            {
                return field;
            }
        }

        return null;
    }

    private static NCard? TryGetCardFromMember(object source, MemberInfo? member)
    {
        if (member is null)
        {
            return null;
        }

        try
        {
            return member switch
            {
                PropertyInfo property => TryAsValidCard(property.GetValue(source)),
                FieldInfo field => TryAsValidCard(field.GetValue(source)),
                _ => null
            };
        }
        catch (Exception ex)
        {
            Log("TryGetCardFromMember failed: " + ex);
            return null;
        }
    }

    private static void RefreshCardOwner(object? source, bool updateMetadata)
    {
        var cardNode = TryFindCardNode(source);
        if (cardNode is not null)
        {
            TryReloadBrokenNativeAncientLayout(cardNode);
            if (updateMetadata)
            {
                UpdateInspectCardMetadataFromCard(cardNode);
            }
            RefreshCardOverridesAfterGameVisualUpdate(cardNode);
        }
    }

    private static void RefreshCardOwnerPostfix(object __instance)
    {
        RefreshCardOwner(__instance, true);
    }

    private static void CaptureCardProviderPostfix(object __instance)
    {
        var cardNode = TryFindCardNode(__instance);
        if (cardNode is null)
        {
            return;
        }

        TryReloadBrokenNativeAncientLayout(cardNode);
        UpdateInspectCardMetadataFromCard(cardNode);
        var manager = TryEnsureManager();
        if (manager is null || _skinChangerOwnsVisuals)
        {
            return;
        }

        if (HasExternalUpdateVisualsPatch())
        {
            manager.Call("set_external_provider_capture_enabled", true);
            manager.Call("capture_card_provider_after_visual_update", cardNode, true);
        }

        // UpdateVisuals can replace the portrait immediately before drawing it. Reapply
        // our override in the same callback so the stock/provider texture never flashes.
        manager.Call("apply_card_override_after_visual_update", cardNode);
        QueueCardOverrideRefresh(cardNode);

        if (_externalUpdateVisualsPatchDetected)
        {
            // Capture once deferred as well in case another last-priority postfix ran after us.
            manager.Call("queue_card_provider_capture", cardNode);
        }
    }

    private static string DescribeNodePath(Node node)
    {
        try
        {
            if (node is null || !GodotObject.IsInstanceValid(node))
            {
                return "<invalid>";
            }

            if (node.IsInsideTree())
            {
                return node.GetPath().ToString();
            }

            var parts = new List<string>();
            var current = node;
            while (current is not null && GodotObject.IsInstanceValid(current))
            {
                parts.Add(current.Name.ToString());
                current = current.GetParent();
            }

            parts.Reverse();
            return "<detached>/" + string.Join("/", parts);
        }
        catch (Exception ex)
        {
            return $"<path unavailable: {ex.GetType().Name}>";
        }
    }

}

[HarmonyPatch(typeof(NInspectCardScreen), nameof(NInspectCardScreen._Ready))]
internal static class InspectCardScreenReadyPatch
{
    private static void Postfix(NInspectCardScreen __instance)
    {
        Bootstrap.OnInspectCardScreenReady(__instance);
    }
}

[HarmonyPatch(typeof(NInspectCardScreen), "UpdateCardDisplay")]
internal static class InspectCardScreenUpdateCardDisplayPatch
{
    [HarmonyPriority(Priority.Last)]
    private static void Postfix(NInspectCardScreen __instance)
    {
        Bootstrap.RefreshInspectCardProvider(__instance);
    }
}

[HarmonyPatch(typeof(NInspectCardScreen), nameof(NInspectCardScreen.Close))]
internal static class InspectCardScreenClosePatch
{
    private static void Prefix(NInspectCardScreen __instance)
    {
        Bootstrap.UnregisterInspectCardProvider(__instance);
        Bootstrap.UpdateInspectCardMetadata(__instance);
    }
}

[HarmonyPatch(typeof(NCard), "Reload")]
internal static class NCardReloadPatch
{
    private static void Postfix(NCard __instance)
    {
        Bootstrap.RefreshCardOverrides(__instance);
    }
}
