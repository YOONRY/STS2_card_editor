using System;
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
    private const string CachedPortraitPathMeta = "_card_art_cached_portrait_path";
    private const string CachedPortraitCardIdMeta = "_card_art_cached_portrait_card_id";
    private const string CachedPortraitModelKeyMeta = "_card_art_cached_portrait_model_key";
    private const string DeferredCardRefreshPendingMeta = "_card_art_deferred_card_refresh_pending";
    private const string DeferredCardRefreshInvalidateModelMeta = "_card_art_deferred_card_refresh_invalidate_model";
    private const string ManagerRefreshModeMeta = "_card_art_event_refresh_configured";
    private const string InfectionEffectSuppressedMeta = "_card_art_infection_effect_suppressed";
    private const string InfectionEffectOriginalVisibleMeta = "_card_art_infection_effect_original_visible";
    private static Node? _pendingManager;
    private static bool _eventDrivenPortraitRefreshEnabled;
    private static MethodBase? _nCardUpdateVisualsMethod;
    private static bool _externalUpdateVisualsPatchDetected;
    private static long _nextExternalPatchProbeTicks;
    private const long ExternalPatchProbeIntervalMs = 1000;
    private static readonly Dictionary<Type, MemberInfo?> CardNodeMemberCache = new();
    private static readonly Dictionary<Type, PropertyInfo?> CustomPortraitPathPropertyCache = new();
    private static string _lastInspectMetadataDiagnostic = string.Empty;

    public static void Init()
    {
        try
        {
            Log("Init start.");
            Harmony.PatchAll(typeof(Bootstrap).Assembly);
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
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Cards.Holders.NCardHolder", "ReassignToCard", nameof(RefreshCardOwnerPostfix));
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Cards.Holders.NCardHolder", "SetCard", nameof(RefreshCardOwnerPostfix));
        TryPatchOptionalPostfix("MegaCrit.Sts2.Core.Nodes.Cards.Holders.NCardHolder", "OnCardReassigned", nameof(RefreshCardOwnerPostfix));
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
            return existing;
        }

        if (_pendingManager is not null && GodotObject.IsInstanceValid(_pendingManager))
        {
            ConfigureManagerRefreshMode(_pendingManager);
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
        if (manager is null)
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
                return;
            }

            var cardId = GetCardId(model);
            var sourcePath = GetCachedPortraitPath(card, model, cardId);
            card.SetMeta(InspectSourcePathMeta, sourcePath);
            card.SetMeta(InspectCardIdMeta, cardId);
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
        if (!HasExternalUpdateVisualsPatch())
        {
            return;
        }

        var cardNode = TryFindCardNode(__instance);
        if (cardNode is null)
        {
            return;
        }

        UpdateInspectCardMetadataFromCard(cardNode);
        var manager = TryEnsureManager();
        if (manager is null)
        {
            return;
        }

        manager.Call("set_external_provider_capture_enabled", true);
        // Capture now and once deferred so load-order ties cannot hide the final provider texture.
        manager.Call("capture_card_provider_after_visual_update", cardNode);
        manager.Call("queue_card_provider_capture", cardNode);
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
