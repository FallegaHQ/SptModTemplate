namespace Softwyx.SptModTemplate.Localization;

/// <summary>Resolve EFT item display names via the game's built-in locale extension.</summary>
[SuppressMessage("ReSharper", "UnusedType.Global")]
[SuppressMessage("ReSharper", "UnusedMember.Global")]
internal static class ItemLocale{
    public static string Name(string templateId){
        return string.IsNullOrEmpty(templateId) ? null : $"{templateId} Name".Localized();
    }

    public static string ShortName(string templateId){
        return string.IsNullOrEmpty(templateId) ? null : $"{templateId} ShortName".Localized();
    }
}
