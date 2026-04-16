using System;
using System.IO;
using System.Collections.Generic;
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
    private static readonly Harmony Harmony = new("ysg05.card_art_editor");
    private static bool _loggedManagerLoadFailure;
    private static bool _loggedManagerInstantiateFailure;
    private static bool _loggedOverlayLoadFailure;
    private const string ManagerNodeName = "CardArtOverrideManager";
    private const string ManagerScriptPath = "res://mods/card_art_editor/card_art_override_manager.gd";
    private const string OverlayScenePath = "res://mods/card_art_editor/inspect_card_art_editor.tscn";
    internal const string InspectSourcePathMeta = "_card_art_inspect_source_path";
    internal const string InspectCardIdMeta = "_card_art_inspect_card_id";
    internal const string SourcePathMeta = "_card_art_source_path";
    internal const string OverrideActiveMeta = "_card_art_override_active";
    internal const string FullArtActiveMeta = "_card_art_full_art_active";
    internal const string FullArtOwnerPathMeta = "_card_art_full_art_owner_path";

    public static void Init()
    {
        try
        {
            Log("Init start.");
            Harmony.PatchAll(typeof(Bootstrap).Assembly);
            TryEnsureManager();
            TryAttachToOpenInspectScreens();
            Log("Init complete.");
        }
        catch (Exception ex)
        {
            Log("Init failed: " + ex);
            GD.PushError($"CardArtEditor: bootstrap failed: {ex}");
        }
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
            return existing;
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
        root.CallDeferred(Node.MethodName.AddChild, manager);
        Log("Manager node queued for add to /root.");
        return manager;
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
                return;
            }

            var manager = TryEnsureManager();
            var cardRoot = card.GetNodeOrNull<Node>("CardContainer");

            if (!TryGetCardModel(card, out var model) || model is null)
            {
                var existingSourcePath = card.HasMeta(InspectSourcePathMeta)
                    ? card.GetMeta(InspectSourcePathMeta, string.Empty).AsString()
                    : string.Empty;
                var existingCardId = card.HasMeta(InspectCardIdMeta)
                    ? card.GetMeta(InspectCardIdMeta, string.Empty).AsString()
                    : string.Empty;

                if (existingSourcePath != string.Empty)
                {
                    card.SetMeta(InspectSourcePathMeta, string.Empty);
                }

                if (existingCardId != string.Empty)
                {
                    card.SetMeta(InspectCardIdMeta, string.Empty);
                }

                return;
            }

            var nextSourcePath = model.PortraitPath ?? string.Empty;
            var nextCardId = model.Id.Entry ?? string.Empty;
            var currentSourcePath = card.HasMeta(InspectSourcePathMeta)
                ? card.GetMeta(InspectSourcePathMeta, string.Empty).AsString()
                : string.Empty;
            var currentCardId = card.HasMeta(InspectCardIdMeta)
                ? card.GetMeta(InspectCardIdMeta, string.Empty).AsString()
                : string.Empty;
            if (currentSourcePath != nextSourcePath)
            {
                card.SetMeta(InspectSourcePathMeta, nextSourcePath);
            }

            if (currentCardId != nextCardId)
            {
                card.SetMeta(InspectCardIdMeta, nextCardId);
            }

        }
        catch (Exception ex)
        {
            Log("UpdateInspectCardMetadata failed: " + ex);
        }
    }

    internal static void RefreshCardOverrides(NCard card)
    {
        try
        {
            if (card is null || !GodotObject.IsInstanceValid(card))
            {
                return;
            }

            var manager = TryEnsureManager();
            if (manager is null)
            {
                return;
            }

            if (!TryGetCardModel(card, out var model) || model is null)
            {
                return;
            }

            var sourcePath = model.PortraitPath ?? string.Empty;
            var cardRoot = card.GetNodeOrNull<Node>("CardContainer");
            var isInfectionCard =
                string.Equals(model.Id.Entry ?? string.Empty, "INFECTION", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(model.GetType().Name ?? string.Empty, "Infection", StringComparison.OrdinalIgnoreCase);
            var infectionSuppressionEnabled = manager.Call("is_infection_effect_hidden_enabled").AsBool();
            var hasOverride = !string.IsNullOrEmpty(sourcePath) && manager.Call("has_override", sourcePath).AsBool();
            var hasAncientTextOutside = !string.IsNullOrEmpty(sourcePath) && manager.Call("is_ancient_text_outside_enabled", sourcePath).AsBool();
            var needsVisualRefresh = CardNeedsVisualRefresh(cardRoot);
            if (!hasOverride && !hasAncientTextOutside && !(infectionSuppressionEnabled && isInfectionCard) && !needsVisualRefresh)
            {
                return;
            }

            if (cardRoot is not null)
            {
                cardRoot.SetMeta(SourcePathMeta, sourcePath);
                if (IsNodeInInspectScreen(cardRoot))
                {
                    UpdateInspectCardMetadataFromCard(card);
                    manager.Call("request_card_root_refresh", cardRoot, 1);
                }
                else
                {
                    manager.Call("request_card_root_refresh", cardRoot, 1);
                }
            }

            TrySuppressSpecialCardEffects(card);
        }
        catch (Exception ex)
        {
            Log("RefreshCardOverrides failed: " + ex);
        }
    }

    private static void TrySuppressSpecialCardEffects(NCard card)
    {
        try
        {
            var manager = TryEnsureManager();
            if (manager is not null)
            {
                var suppressionEnabled = manager.Call("is_infection_effect_hidden_enabled").AsBool();
                if (!suppressionEnabled)
                {
                    return;
                }
            }

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

            HideInfectionEffectNodes(card);
        }
        catch (Exception ex)
        {
            Log("TrySuppressSpecialCardEffects failed: " + ex);
        }
    }

    private static bool TryGetCardModel(NCard card, out CardModel? model)
    {
        model = null;
        try
        {
            model = card.Model;
            return model is not null;
        }
        catch (ModelNotFoundException)
        {
            return false;
        }
        catch (Exception)
        {
            return false;
        }
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
                card.SetMeta(InspectSourcePathMeta, string.Empty);
                card.SetMeta(InspectCardIdMeta, string.Empty);
                return;
            }

            card.SetMeta(InspectSourcePathMeta, model.PortraitPath ?? string.Empty);
            card.SetMeta(InspectCardIdMeta, model.Id.Entry ?? string.Empty);
        }
        catch (Exception ex)
        {
            Log("UpdateInspectCardMetadataFromCard failed: " + ex);
        }
    }

    private static bool CardNeedsVisualRefresh(Node? cardRoot)
    {
        if (cardRoot is null || !GodotObject.IsInstanceValid(cardRoot))
        {
            return false;
        }

        var portrait = cardRoot.GetNodeOrNull<TextureRect>("PortraitCanvasGroup/Portrait");
        if (NodeHasRefreshState(portrait))
        {
            return true;
        }

        var ancientPortrait = cardRoot.GetNodeOrNull<TextureRect>("PortraitCanvasGroup/AncientPortrait");
        if (NodeHasRefreshState(ancientPortrait))
        {
            return true;
        }

        var fullArtLayer = cardRoot.GetNodeOrNull<TextureRect>("PortraitCanvasGroup/CardArtFullArtLayer");
        if (NodeHasRefreshState(fullArtLayer))
        {
            return true;
        }

        return false;
    }

    private static bool NodeHasRefreshState(Node? node)
    {
        if (node is null || !GodotObject.IsInstanceValid(node))
        {
            return false;
        }

        if (node.HasMeta(SourcePathMeta) && !string.IsNullOrEmpty(node.GetMeta(SourcePathMeta, string.Empty).AsString()))
        {
            return true;
        }

        if (node.HasMeta(OverrideActiveMeta) && node.GetMeta(OverrideActiveMeta, false).AsBool())
        {
            return true;
        }

        if (node.HasMeta(FullArtActiveMeta) && node.GetMeta(FullArtActiveMeta, false).AsBool())
        {
            return true;
        }

        if (node.HasMeta(FullArtOwnerPathMeta) && !string.IsNullOrEmpty(node.GetMeta(FullArtOwnerPathMeta, string.Empty).AsString()))
        {
            return true;
        }

        return false;
    }

    private static bool IsNodeInInspectScreen(Node? node)
    {
        var current = node;
        while (current is not null && GodotObject.IsInstanceValid(current))
        {
            if (string.Equals(current.Name?.ToString(), "InspectCardScreen", StringComparison.Ordinal))
            {
                return true;
            }

            current = current.GetParent();
        }

        return false;
    }

    private static void HideInfectionEffectNodes(Node root)
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
                    canvasItem.Visible = false;
                }
            }

            HideInfectionEffectNodes(childNode);
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
    private static void Postfix(NInspectCardScreen __instance)
    {
        Bootstrap.UpdateInspectCardMetadata(__instance);
    }
}

[HarmonyPatch(typeof(NInspectCardScreen), nameof(NInspectCardScreen.Close))]
internal static class InspectCardScreenClosePatch
{
    private static void Prefix(NInspectCardScreen __instance)
    {
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
