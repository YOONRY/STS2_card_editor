using System;
using System.IO;
using System.Collections.Generic;
using Godot;
using HarmonyLib;
using MegaCrit.Sts2.Core.Modding;
using MegaCrit.Sts2.Core.Models;
using MegaCrit.Sts2.Core.Nodes.Cards;
using MegaCrit.Sts2.Core.Nodes.Screens;

namespace CardArtEditorBootstrap;

[ModInitializer("Init")]
public static class Bootstrap
{
    private static readonly Harmony Harmony = new("ysg05.card_art_editor");
    private static readonly HashSet<string> LoggedCardEffectTrees = new();
    private static bool _loggedManagerLoadFailure;
    private static bool _loggedManagerInstantiateFailure;
    private static bool _loggedOverlayLoadFailure;
    private const string ManagerNodeName = "CardArtOverrideManager";
    private const string ManagerScriptPath = "res://mods/card_art_editor/card_art_override_manager.gd";
    private const string OverlayScenePath = "res://mods/card_art_editor/inspect_card_art_editor.tscn";
    internal const string InspectSourcePathMeta = "_card_art_inspect_source_path";
    internal const string InspectCardIdMeta = "_card_art_inspect_card_id";

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
        root.AddChild(manager);
        Log("Manager node added to /root.");
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
                return;
            }

            var model = card.Model;
            if (model is null)
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

            var portrait = card.GetNodeOrNull<TextureRect>("CardContainer/PortraitCanvasGroup/Portrait");
            if (portrait is not null)
            {
                manager.Call("apply_override_to_texture_rect", portrait);
            }

            var ancientPortrait = card.GetNodeOrNull<TextureRect>("CardContainer/PortraitCanvasGroup/AncientPortrait");
            if (ancientPortrait is not null)
            {
                manager.Call("apply_override_to_texture_rect", ancientPortrait);
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

            var model = card.Model;
            if (model is null)
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

            var logKey = $"{cardId}:{card.Name}";
            if (LoggedCardEffectTrees.Add(logKey))
            {
                Log($"Infection card detected. Dumping node tree for {logKey}.");
                DumpNodeTree(card, 0);
            }

            HideInfectionEffectNodes(card);
        }
        catch (Exception ex)
        {
            Log("TrySuppressSpecialCardEffects failed: " + ex);
        }
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
                Log($"Suppressed Infection effect node: {childNode.GetPath()} [{childNode.GetType().Name}]");
            }

            HideInfectionEffectNodes(childNode);
        }
    }

    private static void DumpNodeTree(Node node, int depth)
    {
        if (depth > 6)
        {
            return;
        }

        var indent = new string(' ', depth * 2);
        var visibleInfo = node is CanvasItem canvasItem ? $" visible={canvasItem.Visible}" : string.Empty;
        Log($"{indent}- {node.GetPath()} [{node.GetType().FullName}]{visibleInfo}");

        foreach (var child in node.GetChildren())
        {
            if (child is Node childNode)
            {
                DumpNodeTree(childNode, depth + 1);
            }
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
