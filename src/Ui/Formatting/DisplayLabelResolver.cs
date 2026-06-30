using Softwyx.SptModTemplate.Localization;

namespace Softwyx.SptModTemplate.Ui.Formatting;

/// <summary>
///     Resolve UI labels at display time: game locale first, mod pack second, raw id last.
///     Persist stable ids/codenames in JSON; call this only when rendering player-facing text.
/// </summary>
internal static class DisplayLabelResolver{
    public static string Resolve(string gameKey, string modKey = null, string rawFallback = null){
        if(string.IsNullOrEmpty(gameKey)) return rawFallback ?? string.Empty;

        var fromGame = GameLocaleAccess.TryLocalize(gameKey);

        if(!string.IsNullOrEmpty(fromGame)) return fromGame;

        if(string.IsNullOrEmpty(modKey)) return !string.IsNullOrEmpty(rawFallback) ? rawFallback : gameKey;

        var fromMod = LocaleLoader.TryGet(modKey);

        if(!string.IsNullOrEmpty(fromMod)) return fromMod;

        return !string.IsNullOrEmpty(rawFallback) ? rawFallback : gameKey;
    }
}
