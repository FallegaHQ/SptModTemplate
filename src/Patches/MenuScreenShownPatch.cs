using Softwyx.SptModTemplate.Config;
using Softwyx.SptModTemplate.Core;

namespace Softwyx.SptModTemplate.Patches;

/// <summary>Postfix when the main menu screen is shown (<see cref="MenuScreen.Show" />).</summary>
internal sealed class MenuScreenShownPatch : ModulePatch{
    protected override MethodBase GetTargetMethod(){
        var method = AccessTools.GetDeclaredMethods(typeof(MenuScreen)).
                                 FirstOrDefault(
                                                m => m.Name == nameof(MenuScreen.Show)
                                                  && m.GetParameters().
                                                       Length
                                                  == 3
                                               );

        if(method == null)
            throw new System.InvalidOperationException(
                                                       "MenuScreen.Show with three parameters was not found. Update this patch for your EFT build."
                                                      );

        return method;
    }

    [PatchPostfix]
    private static void Postfix(){
        // Enabled gate: return immediately when the master toggle is off.
        // Alternative for heavy patches: do not call EnablePatch in the plugin while disabled.
        if(!Settings.Enabled.Value) return;

        ModLifecycle.OnMainMenuShown();
    }
}
