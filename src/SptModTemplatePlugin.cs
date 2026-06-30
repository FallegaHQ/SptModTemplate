using Softwyx.SptModTemplate.Config;
using Softwyx.SptModTemplate.Localization;
using Softwyx.SptModTemplate.Patches;

namespace Softwyx.SptModTemplate;

[BepInPlugin(PluginInfo.PLUGIN_GUID, PluginInfo.PLUGIN_NAME, PluginInfo.PLUGIN_VERSION)]
[BepInDependency("com.SPT.core", "4.0.0")]
// Optional — uncomment and set GUID + version when your mod requires another plugin:
// [BepInDependency("com.other.author.othermod", "1.0.0")]
// [BepInDependency("com.fika.core", BepInDependency.DependencyFlags.SoftDependency)]
public class SptModTemplatePlugin : BaseUnityPlugin{
    internal static ManualLogSource      Log;
    internal static SptModTemplatePlugin Instance;

    private void Awake(){
        Instance = this;

        Log = Logger;

        if(!PreloadDefaultLocale()) return;

        Settings.Init(Config);

        Log.LogInfo(PluginInfo.Format($"{PluginInfo.PLUGIN_NAME} v{PluginInfo.PLUGIN_VERSION} loaded (BepInEx)."));

        EnablePatch<LocaleApplicationLanguagePatch>("LocaleApplicationLanguagePatch");
        EnablePatch<MenuScreenShownPatch>("MenuScreenShownPatch");
        EnablePatch<RaidStartedPatch>("RaidStartedPatch");
    }

    private static bool PreloadDefaultLocale(){
        if(LocaleLoader.PreloadDefaultLocale(out var error)) return true;

        Log.LogError(PluginInfo.Format($"Locale preload failed: {error} Mod patches were not enabled."));

        return false;
    }

    private static void EnablePatch<T>(string name) where T : ModulePatch, new(){
        try{
            new T().Enable();

            Log.LogInfo(PluginInfo.Format($"{name} enabled."));
        }

        catch(System.Exception ex){
            Log.LogError(PluginInfo.Format($"{name} failed: {ex}"));
        }
    }
}
