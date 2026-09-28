using System.Collections;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Text.Json;
using HarmonyLib;

namespace CardArtEditorBootstrap;

internal static class SkinChangerStartupBridge
{
    private const BindingFlags Static = BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic;
    private const BindingFlags Instance = BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic;
    private static readonly ConditionalWeakTable<object, Publication> Publications = new();
    private static HashSet<string> _importedPaths = new(StringComparer.OrdinalIgnoreCase);
    private static readonly HashSet<string> PendingReleasedPaths = new(StringComparer.OrdinalIgnoreCase);
    private static string _packDirectory = string.Empty;
    private static bool _installed;

    private sealed class Publication
    {
        public string Stamp = string.Empty;
        public HashSet<string> Imports = new(StringComparer.OrdinalIgnoreCase);
    }

    internal static void Install(Harmony harmony, Assembly assembly, string dataDirectory)
    {
        if (_installed)
        {
            return;
        }
        var scanner = assembly.GetType("STS2SkinChanger.Catalog.CardArtPackScanner", true)!;
        var service = assembly.GetType("STS2SkinChanger.Core.SkinService", true)!;
        var catalog = assembly.GetType("STS2SkinChanger.Catalog.SkinCatalog", true)!;
        var enumerate = scanner.GetMethod("EnumeratePackFiles", Static)
            ?? throw new MissingMethodException(scanner.FullName, "EnumeratePackFiles");
        var roots = service.GetMethod("CardArtPackScanRoots", Static)
            ?? throw new MissingMethodException(service.FullName, "CardArtPackScanRoots");
        var attach = catalog.GetMethod("AttachCardArtPacks", Instance)
            ?? throw new MissingMethodException(catalog.FullName, "AttachCardArtPacks");
        _packDirectory = Path.Combine(dataDirectory, "skin_changer", "CAE_Saved_Art");
        _importedPaths = ReadImportedPaths(Path.Combine(dataDirectory, "art_pack_registry.json"));
        try
        {
            harmony.Patch(enumerate, postfix: new HarmonyMethod(typeof(SkinChangerStartupBridge), nameof(FilterPackFiles)));
            harmony.Patch(roots, postfix: new HarmonyMethod(typeof(SkinChangerStartupBridge), nameof(AddUnifiedRoot)));
            harmony.Patch(attach, postfix: new HarmonyMethod(typeof(SkinChangerStartupBridge), nameof(ConfigureAttachedPack)));
            _installed = true;
        }
        catch
        {
            // Do not leave a half-installed filter hiding packs without a replacement.
            foreach (var method in new[] { enumerate, roots, attach })
            {
                harmony.Unpatch(method, HarmonyPatchType.Postfix, harmony.Id);
            }
            throw;
        }
    }

    internal static HashSet<string> ReadImportedPaths(string registryPath)
    {
        var paths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        if (!File.Exists(registryPath))
        {
            return paths;
        }
        using var stream = File.OpenRead(registryPath);
        using var document = JsonDocument.Parse(stream);
        var root = document.RootElement;
        if (!root.TryGetProperty("packs", out var packs) || packs.ValueKind != JsonValueKind.Object ||
            !root.TryGetProperty("workshop_sources", out var sources) || sources.ValueKind != JsonValueKind.Object)
        {
            return paths;
        }
        foreach (var source in sources.EnumerateObject())
        {
            var value = source.Value;
            if (value.ValueKind == JsonValueKind.Object && value.TryGetProperty("pack_id", out var id) &&
                id.ValueKind == JsonValueKind.String && !string.IsNullOrEmpty(id.GetString()) && packs.TryGetProperty(id.GetString()!, out _) &&
                value.TryGetProperty("path", out var path) && path.ValueKind == JsonValueKind.String)
            {
                var normalized = NormalizePath(path.GetString()!);
                if (normalized.Length > 0)
                {
                    paths.Add(normalized);
                }
            }
        }
        return paths;
    }

    internal static string[] UpdateImportedPaths(IEnumerable<string> paths)
    {
        var next = paths.Select(NormalizePath).Where(path => path.Length > 0).ToHashSet(StringComparer.OrdinalIgnoreCase);
        PendingReleasedPaths.UnionWith(_importedPaths.Except(next, StringComparer.OrdinalIgnoreCase));
        PendingReleasedPaths.ExceptWith(next);
        _importedPaths = next;
        return PendingReleasedPaths.ToArray();
    }

    private static void FilterPackFiles(ref IEnumerable<string> __result)
    {
        // Filter the lazy file list before Describe or Scan reads any image data.
        var snapshot = _importedPaths;
        __result = __result.Where(path => !snapshot.Contains(NormalizePath(path)));
    }

    private static void AddUnifiedRoot(ref IReadOnlyList<string> __result)
    {
        if (File.Exists(Path.Combine(_packDirectory, "cae_saved_art.cardartpack.json")))
        {
            __result = __result.Append(_packDirectory).Distinct(StringComparer.OrdinalIgnoreCase).ToArray();
        }
    }

    private static void ConfigureAttachedPack(object __instance, IEnumerable packs, IEnumerable cards)
    {
        var unified = packs.Cast<object>().Where(pack =>
            pack.GetType().GetProperty("Id")?.GetValue(pack) as string == SkinChangerCatalogBridge.PackId).ToArray();
        if (unified.Length == 0)
        {
            return;
        }
        SkinChangerCatalogBridge.ConfigurePresentations(__instance, cards, unified);
        var service = __instance.GetType().Assembly.GetType("STS2SkinChanger.Core.SkinService");
        if (service?.GetField("_cardGroupsInitialized", Static)?.GetValue(null) is true)
        {
            // Runtime refresh is only committed after cache invalidation succeeds.
            return;
        }
        foreach (var pack in unified)
        {
            var type = pack.GetType();
            if (type.GetProperty("Id")?.GetValue(pack) as string == SkinChangerCatalogBridge.PackId &&
                string.Equals(NormalizePath(type.GetProperty("Path")?.GetValue(pack) as string ?? string.Empty),
                    NormalizePath(Path.Combine(_packDirectory, "cae_saved_art.cardartpack.json")), StringComparison.OrdinalIgnoreCase))
            {
                MarkPublished(__instance, _packDirectory);
            }
        }
    }

    internal static void MarkPublished(object catalog, string directory)
    {
        var state = Publications.GetOrCreateValue(catalog);
        state.Stamp = PackStamp(directory);
        state.Imports = new HashSet<string>(_importedPaths, StringComparer.OrdinalIgnoreCase);
        PendingReleasedPaths.Clear();
    }

    internal static bool IsPublished(object catalog, string directory, IEnumerable<string> imports)
    {
        return Publications.TryGetValue(catalog, out var state) && state.Stamp == PackStamp(directory) &&
            state.Imports.SetEquals(imports.Select(NormalizePath));
    }

    private static string PackStamp(string directory)
    {
        var file = new FileInfo(Path.Combine(directory, "cae_saved_art.cardartpack.json"));
        return NormalizePath(file.FullName) + (file.Exists ? $"|{file.Length}|{file.LastWriteTimeUtc.Ticks}" : "|missing");
    }

    private static string NormalizePath(string path)
    {
        try
        {
            return string.IsNullOrWhiteSpace(path) ? string.Empty : Path.GetFullPath(path).Replace('\\', '/');
        }
        catch (ArgumentException) { return string.Empty; }
        catch (NotSupportedException) { return string.Empty; }
        catch (PathTooLongException) { return string.Empty; }
    }
}
