namespace Softwyx.SptModTemplate;

/// <summary>Plugin identity. <see cref="PLUGIN_VERSION" /> is generated in PluginInfo.Version.g.cs on each build.</summary>
[SuppressMessage("ReSharper", "InconsistentNaming")]
internal static partial class PluginInfo{
    public const  string PLUGIN_GUID = "com.softwyx.sptmodtemplate";
    public const  string PLUGIN_NAME = "Spt Mod Template";
    private const string LogPrefix   = "SMT";

    public static string Format(string message){
        return $"[{LogPrefix}] {message}";
    }
}
