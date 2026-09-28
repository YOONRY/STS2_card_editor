using System.Collections;
using System.Reflection;
using System.Runtime.CompilerServices;

namespace CardArtEditorBootstrap;

// All reflection is confined to catalog changes, never per-card draw callbacks.
internal static class SkinChangerCatalogBridge
{
    internal const string PackId = "cae_saved_art";
    private const BindingFlags Instance = BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic;
    private const BindingFlags Static = BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic;
    private static readonly ConditionalWeakTable<object, List<(string Group, object Option)>> HiddenOptions = new();

    private static object? Read(object value, string property) => value.GetType().GetProperty(property, Instance)?.GetValue(value);
    private static string Text(object value, string property) => Read(value, property) as string ?? string.Empty;
    private static IDictionary Groups(object catalog) =>
        catalog.GetType().GetField("_artPackCardGroups", Instance)?.GetValue(catalog) as IDictionary
        ?? throw new MissingFieldException(catalog.GetType().FullName, "_artPackCardGroups");

    internal static void ConfigurePresentations(object catalog, IEnumerable entries, IEnumerable packs)
    {
        var metadata = entries.Cast<object>().GroupBy(entry => Text(entry, "TypeName"), StringComparer.OrdinalIgnoreCase)
            .ToDictionary(group => group.Key, group => group.First(), StringComparer.OrdinalIgnoreCase);
        var modes = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var pack in packs.Cast<object>().Where(pack => Text(pack, "Id") == PackId))
        {
            foreach (var card in ((IEnumerable)Read(pack, "Cards")!).Cast<object>())
            {
                modes[Text(card, "SourcePath")] = Text(card, "DisplayMode");
            }
        }
        var groups = Groups(catalog);
        var mirrors = new List<(string Group, object Option)>();
        foreach (DictionaryEntry pair in groups)
        {
            foreach (var option in ((IEnumerable)Read(pair.Value!, "Options")!).Cast<object>().Where(option => Text(option, "Id") == PackId))
            {
                var portraits = (IDictionary)Read(option, "NormalPortraits")!;
                var presentations = (IDictionary)Read(option, "CardPresentations")!;
                var filterTypes = new Dictionary<string, HashSet<string>>(StringComparer.OrdinalIgnoreCase);
                foreach (DictionaryEntry portrait in portraits)
                {
                    var typeName = (string)portrait.Key;
                    if (!metadata.TryGetValue(typeName, out var entry))
                    {
                        continue;
                    }
                    var filter = Text(entry, "FilterGroupId");
                    var ancient = filter.Equals("ancients", StringComparison.OrdinalIgnoreCase) ||
                        modes.GetValueOrDefault((string)portrait.Value!) == "full_art";
                    presentations[typeName] = CreatePresentation(catalog.GetType().Assembly, ancient);
                    if (!string.IsNullOrEmpty(filter) && !filter.Equals((string)pair.Key, StringComparison.OrdinalIgnoreCase))
                    {
                        if (!filterTypes.TryGetValue(filter, out var types))
                        {
                            types = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                            filterTypes[filter] = types;
                        }
                        types.Add(typeName);
                    }
                }
                foreach (var filter in filterTypes)
                {
                    mirrors.Add((filter.Key, SliceOption(option, filter.Value)));
                }
            }
        }
        // Skin Changer resolves native Ancient cards through their filter group.
        // Its art-pack attach API registers only the pool group, unlike PCK mods.
        foreach (var mirror in mirrors)
        {
            AddOption(catalog, groups, mirror.Group, mirror.Option);
        }
    }

    private static object CreatePresentation(Assembly assembly, bool ancient)
    {
        var type = assembly.GetType("STS2SkinChanger.Catalog.CardPresentationDefinition", true)!;
        var constructor = type.GetConstructors(Instance).OrderByDescending(candidate => candidate.GetParameters().Length).First();
        var values = new Dictionary<string, object>(StringComparer.OrdinalIgnoreCase)
        {
            ["UseAncientLayout"] = ancient,
            ["UseFullFrameArt"] = false,
            ["UseExpandedPortraitLayout"] = false,
            ["PortraitVisible"] = true,
            ["FrameVisible"] = true,
            ["BannerVisible"] = true,
            ["TextBackgroundVisible"] = true,
            ["PortraitBorderVisible"] = !ancient,
            ["TypePlaqueVisible"] = true,
            ["TypeLabelVisible"] = true
        };
        return constructor.Invoke(constructor.GetParameters().Select(parameter =>
            values.TryGetValue(parameter.Name!, out var value) ? value : parameter.DefaultValue).ToArray());
    }

    private static object SliceOption(object option, HashSet<string> types)
    {
        var clone = option.GetType().GetMethod("<Clone>$", Instance)!.Invoke(option, null)!;
        var portraits = (IDictionary)Read(option, "NormalPortraits")!;
        var paths = portraits.Keys.Cast<string>().Where(types.Contains)
            .Select(key => (string)portraits[key]!).ToHashSet(StringComparer.OrdinalIgnoreCase);
        foreach (var name in new[] { "NormalPortraits", "AncientPortraits", "Assets", "CardPresentations", "CardNames", "CardSurfaces" })
        {
            if (Read(option, name) is not IDictionary source)
            {
                continue;
            }
            var subset = (IDictionary)Activator.CreateInstance(source.GetType())!;
            foreach (DictionaryEntry pair in source)
            {
                if ((name == "Assets" ? paths : types).Contains((string)pair.Key))
                {
                    subset.Add(pair.Key, pair.Value);
                }
            }
            clone.GetType().GetProperty(name, Instance)!.SetValue(clone, subset);
        }
        return clone;
    }

    internal static HashSet<string> FilterImportedPacks(object catalog, IEnumerable<string> importedPaths)
    {
        var groups = Groups(catalog);
        var affected = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var hidden = HiddenOptions.GetOrCreateValue(catalog);
        // Restore our last filter first so unregistering a pack is reversible.
        foreach (var previous in hidden)
        {
            AddOption(catalog, groups, previous.Group, previous.Option);
            affected.Add(previous.Group);
        }
        hidden.Clear();
        var identities = ResolveImportedIdentities(catalog.GetType().Assembly, importedPaths);
        foreach (DictionaryEntry pair in groups)
        {
            var options = (IList)Read(pair.Value!, "Options")!;
            for (var index = options.Count - 1; index >= 0; index--)
            {
                var option = options[index]!;
                var id = Text(option, "Id");
                var root = NormalizeRoot(Text(option, "ProviderRootPath"));
                if (id == PackId || !identities.Any(identity => identity.Id.Equals(id, StringComparison.OrdinalIgnoreCase) && identity.Root.Equals(root, StringComparison.OrdinalIgnoreCase)))
                {
                    continue;
                }
                hidden.Add(((string)pair.Key, option));
                options.RemoveAt(index);
                affected.Add((string)pair.Key);
            }
        }
        return affected;
    }

    private static List<(string Id, string Root)> ResolveImportedIdentities(Assembly assembly, IEnumerable<string> paths)
    {
        var scanner = assembly.GetType("STS2SkinChanger.Catalog.CardArtPackScanner", true)!;
        var policy = assembly.GetType("STS2SkinChanger.Catalog.CardArtPackScanPolicy", true)!;
        var metadata = scanner.GetMethod("ReadMetadata", Static)!;
        var normalizeId = policy.GetMethod("NormalizePackId", Static)!;
        var result = new List<(string, string)>();
        foreach (var path in paths.Distinct(StringComparer.OrdinalIgnoreCase))
        {
            if (!File.Exists(path))
            {
                continue;
            }
            var root = Path.GetDirectoryName(Path.GetFullPath(path))!;
            var description = metadata.Invoke(null, new object[] { root })!;
            var declaredId = description.GetType().GetField("Item1")!.GetValue(description) as string;
            var id = (string)normalizeId.Invoke(null, new object?[] { declaredId, Path.GetFileName(path) })!;
            result.Add((id, NormalizeRoot(root)));
        }
        return result;
    }

    private static string NormalizeRoot(string root) => root.Replace('\\', '/').TrimEnd('/');

    private static void AddOption(object catalog, IDictionary groups, string groupId, object option) =>
        catalog.GetType().GetMethod("AddCardOption", Static)!.Invoke(null, new object[] { groups, groupId, option });
}
