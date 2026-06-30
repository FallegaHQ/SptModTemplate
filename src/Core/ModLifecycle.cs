using Softwyx.SptModTemplate.Config;
using Softwyx.SptModTemplate.Localization;
using Softwyx.SptModTemplate.Ui.Formatting;

namespace Softwyx.SptModTemplate.Core;

internal static class ModLifecycle{
    private static bool _mainMenuHandled;
    private static bool _raidStartedLogged;

    public static void OnRaidStarted(){
        if(_raidStartedLogged) return;

        _raidStartedLogged = true;
        SptModTemplatePlugin.Log.LogInfo(PluginInfo.Format("Raid started (example hook)."));
    }

    public static void OnMainMenuShown(){
        if(_mainMenuHandled) return;

        _mainMenuHandled = true;

        SptModTemplatePlugin.Log.LogInfo(PluginInfo.Format("Main menu is visible."));

        if(!Settings.ShowWelcomeDialog.Value) return;

        if(SptModTemplatePlugin.Instance == null) return;

        SptModTemplatePlugin.Instance.StartCoroutine(ShowWelcomeDialogWhenReady());
    }

    private static IEnumerator ShowWelcomeDialogWhenReady(){
        const int maxFrames = 180;

        for(var frame = 0; frame < maxFrames; frame++){
            if(!Settings.Enabled.Value) yield break;

            var ui = ItemUiContext.Instance;

            if(ui){
                var title    = LocaleLoader.Get(LocaleKeys.WelcomeTitle);
                var mapLabel = DisplayLabelResolver.Resolve("bigmap", LocaleKeys.ExampleMapFallback);
                var body     = LocaleLoader.Get(LocaleKeys.WelcomeBody, PluginInfo.PLUGIN_VERSION, mapLabel);

                ui.ShowMessageWindow(body, null, null, title, 0f, true);

                SptModTemplatePlugin.Log.LogInfo(PluginInfo.Format("Welcome dialog shown."));

                yield break;
            }

            yield return null;
        }

        SptModTemplatePlugin.Log.LogWarning(
                                            PluginInfo.Format(
                                                              "ItemUiContext was not ready; welcome dialog was skipped."
                                                             )
                                           );
    }
}
