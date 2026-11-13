using System;
using System.Collections.Generic;
using System.Linq;
using Godot;
using HarmonyLib;
using MegaCrit.Sts2.Core.Models;
using MegaCrit.Sts2.Core.Nodes.Screens.CardLibrary;

namespace CardArtEditorBootstrap;

internal static class CardLibraryExportBridge
{
    private const string RequestSignal = "library_export_context_requested";
    private const string CardsMeta = "_card_art_export_library_cards";
    private const string NameMeta = "_card_art_export_library_name";
    private static readonly System.Reflection.FieldInfo? PoolFiltersField =
        AccessTools.Field(typeof(NCardLibrary), "_poolFilters");
    private static readonly System.Reflection.FieldInfo? GridField =
        AccessTools.Field(typeof(NCardLibrary), "_grid");
    private static readonly System.Reflection.FieldInfo? AllCardsField =
        AccessTools.Field(typeof(NCardLibraryGrid), "_allCards");

    internal static void Bind(Control overlay)
    {
        if (overlay.HasSignal(RequestSignal))
        {
            overlay.Connect(RequestSignal, Callable.From(() => Refresh(overlay)));
        }
    }

    private static void Refresh(Control overlay)
    {
        overlay.SetMeta(CardsMeta, new Godot.Collections.Array());
        overlay.SetMeta(NameMeta, string.Empty);
        try
        {
            // Read the game's predicates, not portrait folders or recycled visible card nodes.
            var library = FindVisibleLibrary(overlay.GetTree().Root);
            if (library is null || !TryGetSelectedCategory(library, out var filter, out var models))
            {
                return;
            }

            var cards = new Godot.Collections.Array();
            foreach (var model in models)
            {
                // State-dependent artwork and beta-only cards are not necessarily
                // represented by the canonical model's current PortraitPath.
                var paths = new HashSet<string>(model.AllPortraitPaths, StringComparer.Ordinal)
                {
                    Bootstrap.GetPreferredPortraitPath(model)
                };
                if (model.HasBetaPortrait)
                {
                    paths.Add(model.BetaPortraitPath);
                }
                foreach (var path in paths)
                {
                    cards.Add(new Godot.Collections.Dictionary
                    {
                        ["source_path"] = path,
                        ["card_id"] = model.Id.Entry ?? string.Empty,
                        ["is_base_game_model"] = model.GetType().Assembly == typeof(CardModel).Assembly
                    });
                }
            }

            overlay.SetMeta(CardsMeta, cards);
            overlay.SetMeta(NameMeta, filter!.Loc?.GetFormattedText() ?? filter.Name.ToString());
        }
        catch (Exception ex)
        {
            // Fail closed if the game's library API changes; never export all cards instead.
            overlay.SetMeta(CardsMeta, new Godot.Collections.Array());
            overlay.SetMeta(NameMeta, string.Empty);
            GD.PushWarning("CardArtEditor: could not read the current compendium category: " + ex.Message);
        }
    }

    internal static bool TryGetSelectedCategory(NCardLibrary library, out NCardPoolFilter? filter, out CardModel[] cards)
    {
        filter = null;
        cards = Array.Empty<CardModel>();
        if (PoolFiltersField?.GetValue(library) is not Dictionary<NCardPoolFilter, Func<CardModel, bool>> filters ||
            GridField?.GetValue(library) is not NCardLibraryGrid grid ||
            AllCardsField?.GetValue(grid) is not IEnumerable<CardModel> allCards)
        {
            return false;
        }
        var selected = filters.Where(pair => pair.Key.IsSelected).ToArray();
        if (selected.Length != 1)
        {
            return false;
        }
        filter = selected[0].Key;
        cards = allCards.Where(selected[0].Value).ToArray();
        return true;
    }

    private static NCardLibrary? FindVisibleLibrary(Node root)
    {
        if (root is NCardLibrary library)
        {
            return library.IsVisibleInTree() ? library : null;
        }
        foreach (var child in root.GetChildren())
        {
            var found = FindVisibleLibrary(child);
            if (found is not null)
            {
                return found;
            }
        }
        return null;
    }
}
