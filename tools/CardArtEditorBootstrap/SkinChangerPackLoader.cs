using System.Reflection;
using System.Threading.Tasks;

namespace CardArtEditorBootstrap;

// Scan parses files/base64 only. Catalog mutation and all Godot access stay on
// the game thread. At most one scan runs, even while the user makes more edits.
internal static class SkinChangerPackLoader
{
    private static Task<object?>? _scan;
    private static string _stamp = string.Empty;

    internal static bool TryRead(Assembly assembly, string[] roots, out object? result)
    {
        result = null;
        var stamp = Stamp(roots);
        if (_scan is not null)
        {
            if (!_scan.IsCompleted) return false;
            var completed = _scan;
            _scan = null;
            if (_stamp == stamp)
            {
                result = completed.GetAwaiter().GetResult();
                return result is not null;
            }
            // Observe failed obsolete work; a newer snapshot will be retried.
            _ = completed.Exception;
        }
        var scanner = assembly.GetType("STS2SkinChanger.Catalog.CardArtPackScanner", true)!;
        var method = scanner.GetMethod("Scan", BindingFlags.Public | BindingFlags.Static)
            ?? throw new MissingMethodException(scanner.FullName, "Scan");
        _stamp = stamp;
        var snapshot = roots.ToArray();
        _scan = Task.Run(() => method.Invoke(null, new object[] { snapshot }));
        return false;
    }

    private static string Stamp(IEnumerable<string> roots) => string.Join("\n", roots.Select(root =>
        root + "|" + (Directory.Exists(root) ? string.Join("|", Directory.EnumerateFiles(root, "*.json")
            .OrderBy(path => path, StringComparer.OrdinalIgnoreCase).Select(path =>
            {
                var file = new FileInfo(path);
                return $"{path}:{file.Length}:{file.LastWriteTimeUtc.Ticks}";
            })) : "missing")));
}
