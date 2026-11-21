using System.Collections;
using System.Reflection;

namespace CardArtEditorBootstrap;

// Only used when the catalog changes. Never clear another provider's textures.
internal static class SkinChangerRuntimeBridge
{
    private const BindingFlags Static = BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic;
    private const BindingFlags Instance = BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic;

    internal static bool IsOwnedKey(string key) =>
        key.Split('\n').Any(part => part.Equals(SkinChangerCatalogBridge.PackId, StringComparison.OrdinalIgnoreCase));

    internal static void InvalidateTextures(Type service)
    {
        var isolatedPaths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        if (service.GetField("IsolatedCardOverlayCache", Static)?.GetValue(null) is IDictionary overlays)
        {
            foreach (var key in overlays.Keys.Cast<string>().Where(IsOwnedKey).ToArray())
            {
                var overlay = overlays[key];
                if (overlay?.GetType().GetProperty("ResourcePaths", Instance)?.GetValue(overlay) is IDictionary paths)
                {
                    foreach (var path in paths.Values.OfType<string>()) isolatedPaths.Add(path);
                }
                overlays.Remove(key);
            }
        }
        foreach (var field in new[] { "CardPortraitCache", "ExternalCardProviderIdentityPaths", "RuntimeResourceCache" })
        {
            RemoveKeys(service.GetField(field, Static)?.GetValue(null), IsOwnedKey);
        }
        if (service.GetField("FailedCardPortraitRequests", Static)?.GetValue(null) is HashSet<string> failed)
            failed.RemoveWhere(IsOwnedKey);

        // Newer Skin Changer versions cache decoded raw bytes separately from
        // CardPortraitCache. Evict via its bookkeeping method, without disposing
        // textures which an on-screen card may still reference.
        var session = service.GetField("SessionCardPortraits", Static)?.GetValue(null);
        if (session is null) return;
        var type = session.GetType();
        var remove = type.GetMethod("RemoveEntry", Instance);
        bool Affected(string key) => IsOwnedKey(key) || isolatedPaths.Contains(key);
        if (type.GetField("_entries", Instance)?.GetValue(session) is IDictionary entries)
        {
            foreach (var key in entries.Keys.Cast<string>().Where(Affected).ToArray())
            {
                if (remove is null) throw new MissingMethodException(type.FullName, "RemoveEntry");
                remove.Invoke(session, new[] { key, entries[key] });
            }
        }
        if (type.GetField("_failedPaths", Instance)?.GetValue(session) is HashSet<string> failedPaths)
            failedPaths.RemoveWhere(key => Affected(key));
    }

    private static void RemoveKeys(object? cache, Func<string, bool> predicate)
    {
        if (cache is null) return;
        var type = cache.GetType();
        var keys = type.GetProperty("Keys", Instance)?.GetValue(cache) as IEnumerable;
        var remove = type.GetMethod("Remove", Instance, null, new[] { typeof(string) }, null);
        if (keys is null || remove is null) throw new NotSupportedException("Unsupported portrait cache: " + type.FullName);
        foreach (var key in keys.Cast<string>().Where(predicate).ToArray()) remove.Invoke(cache, new object[] { key });
    }
}
