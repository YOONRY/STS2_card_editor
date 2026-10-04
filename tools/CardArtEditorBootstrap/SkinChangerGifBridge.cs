using System.Reflection;
using System.Runtime.CompilerServices;
using System.Threading;
using Godot;
using HarmonyLib;
using MegaCrit.Sts2.Core.Models;
using MegaCrit.Sts2.Core.Nodes.Cards;

namespace CardArtEditorBootstrap;

internal static class SkinChangerGifBridge
{
    private const string SourceMeta = "_cae_skin_changer_gif_source";
    private const string BoundMeta = "_cae_skin_changer_gif_bound";
    private static bool _installAttempted;
    private static WeakReference<Node>? _manager;
    private static Func<CardModel, object?>? _request;
    private static PropertyInfo? _requestSelection;
    private static PropertyInfo? _requestSource;
    private static PropertyInfo? _requestUsesProvider;
    private static Action<string>? _log;
    private static string _lastError = string.Empty;
    private sealed class ModelIdentity
    {
        internal readonly long Token = Interlocked.Increment(ref _nextModelToken);
    }
    private static long _nextModelToken;
    private static readonly ConditionalWeakTable<CardModel, ModelIdentity> ModelIdentities = new();
    private static readonly HashSet<string> ReportedBindings = new(StringComparer.OrdinalIgnoreCase);

    internal static void Configure(Harmony harmony, Assembly assembly, Node manager, Action<string> log)
    {
        _manager = new WeakReference<Node>(manager);
        _log = log;
        if (_installAttempted)
        {
            return;
        }
        // An unsupported Skin Changer API should fall back once, not retry
        // Harmony installation and log exceptions on every card refresh.
        _installAttempted = true;
        const BindingFlags flags = BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic;
        var service = assembly.GetType("STS2SkinChanger.Core.SkinService", true)!;
        var controls = assembly.GetType("STS2SkinChanger.Ui.CardSkinControls", true)!;
        var load = service.GetMethod("LoadIsolatedCardPortrait", flags)
            ?? throw new MissingMethodException(service.FullName, "LoadIsolatedCardPortrait");
        var apply = controls.GetMethod("ApplySelectedPortraitToNode", flags)
            ?? throw new MissingMethodException(controls.FullName, "ApplySelectedPortraitToNode");
        var release = controls.GetMethod("ReleasePresentationForReuse", flags)
            ?? throw new MissingMethodException(controls.FullName, "ReleasePresentationForReuse");
        var request = service.GetMethod("ResolveCardPortraitRequest", flags)
            ?? throw new MissingMethodException(service.FullName, "ResolveCardPortraitRequest");
        _request = request.CreateDelegate<Func<CardModel, object?>>();
        _requestSelection = request.ReturnType.GetProperty("Selection") ?? throw new MissingMemberException("Selection");
        _requestSource = request.ReturnType.GetProperty("ResourcePath") ?? throw new MissingMemberException("ResourcePath");
        _requestUsesProvider = request.ReturnType.GetProperty("UseSelectedProvider") ?? throw new MissingMemberException("UseSelectedProvider");
        try
        {
            harmony.Patch(load, postfix: new HarmonyMethod(typeof(SkinChangerGifBridge), nameof(TagAnimation)));
            harmony.Patch(apply, postfix: new HarmonyMethod(typeof(SkinChangerGifBridge), nameof(BindCard)));
            harmony.Patch(release, postfix: new HarmonyMethod(typeof(SkinChangerGifBridge), nameof(ReleaseCard)));
            log("Skin Changer visible-card GIF playback installed.");
        }
        catch
        {
            foreach (var method in new[] { load, apply, release })
            {
                harmony.Unpatch(method, HarmonyPatchType.Postfix, harmony.Id);
            }
            throw;
        }
    }

    internal static bool ShouldProvideAnimation(string selection, bool useSelectedProvider) =>
        useSelectedProvider && selection.Equals(SkinChangerCatalogBridge.PackId, StringComparison.OrdinalIgnoreCase);

    // CardModel is a plain CLR object and is not exposed by NCard.Get("Model").
    // Pass reference identity across the C#/GDScript boundary as a Variant-safe token.
    internal static long GetModelToken(CardModel? model) => model is null
        ? 0 : ModelIdentities.GetValue(model, static _ => new ModelIdentity()).Token;

    private static Node? Manager() => _manager is not null && _manager.TryGetTarget(out var manager) &&
        GodotObject.IsInstanceValid(manager) ? manager : null;

    private static void TagAnimation(string selection, string resourcePath, bool useSelectedProvider, Texture2D? __result)
    {
        if (__result is null || !ShouldProvideAnimation(selection, useSelectedProvider))
        {
            return;
        }
        try
        {
            // Preserve Skin Changer's cache/identity and do not decode frames during its preload.
            Manager()?.Call("tag_skin_changer_gif_texture", resourcePath, __result);
        }
        catch (Exception ex) { Report(ex); }
    }

    private static void BindCard(NCard card)
    {
        try
        {
            if (!GodotObject.IsInstanceValid(card))
            {
                return;
            }
            var candidate = IsAnimatedPortrait(card.GetNodeOrNull<TextureRect>("%Portrait")) ||
                IsAnimatedPortrait(card.GetNodeOrNull<TextureRect>("%AncientPortrait"));
            if (!candidate && !card.HasMeta(BoundMeta))
            {
                return;
            }
            var model = card.Model;
            var request = model is not null ? _request?.Invoke(model) : null;
            var source = request is not null && ShouldProvideAnimation(
                _requestSelection?.GetValue(request) as string ?? string.Empty,
                _requestUsesProvider?.GetValue(request) is true)
                    ? _requestSource?.GetValue(request) as string ?? string.Empty : string.Empty;
            var manager = Manager();
            var bound = manager is not null && manager.Call("bind_skin_changer_gif_card", card, source, GetModelToken(model)).AsBool();
            if (bound)
            {
                card.SetMeta(BoundMeta, true);
            }
            else
            {
                card.RemoveMeta(BoundMeta);
            }
            if (candidate && source.Length > 0 && ReportedBindings.Count < 8 && ReportedBindings.Add(source))
            {
                _log?.Invoke($"Skin Changer GIF binding {(bound ? "attached" : "skipped")}: {source}");
            }
        }
        catch (Exception ex) { Report(ex); }
    }

    private static bool IsAnimatedPortrait(TextureRect? portrait)
    {
        if (portrait is null || !portrait.Visible)
        {
            return false;
        }
        var texture = portrait.Texture;
        for (var depth = 0; depth <= 4 && texture is not null; depth++)
        {
            if (texture.HasMeta(SourceMeta))
            {
                return true;
            }
            texture = texture is AtlasTexture atlas ? atlas.Atlas : null;
        }
        return false;
    }

    private static void ReleaseCard(NCard card)
    {
        try
        {
            if (!GodotObject.IsInstanceValid(card) || !card.HasMeta(BoundMeta))
            {
                return;
            }
            Manager()?.Call("release_skin_changer_gif_card", card);
            if (GodotObject.IsInstanceValid(card))
            {
                card.RemoveMeta(BoundMeta);
            }
        }
        catch (Exception ex) { Report(ex); }
    }

    private static void Report(Exception error)
    {
        var message = error.GetBaseException().Message;
        if (message != _lastError)
        {
            _lastError = message;
            _log?.Invoke("Skin Changer GIF bridge kept the static fallback: " + message);
        }
    }
}
