namespace Softwyx.SptModTemplate.Interop;

/// <summary>Obfuscated Assembly-CSharp member names. Reference these instead of raw strings in mod logic.</summary>
internal static class GameAssemblyNames{
    internal static class LocaleManagerProperties{
        /// <summary>Requested / selected UI language (e.g. <c>en</c>, <c>ru</c>).</summary>
        public const string SelectedLanguage = "String_0";

        /// <summary>Locale id → merged key/value table for that language.</summary>
        public const string LocalizedTablesByLocaleId = "Dictionary_4";
    }

    internal static class LocaleManagerMethods{
        public const string UpdateApplicationLanguage = nameof(LocaleManagerClass.UpdateApplicationLanguage);
    }
}
