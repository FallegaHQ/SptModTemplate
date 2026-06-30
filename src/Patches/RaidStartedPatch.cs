using Softwyx.SptModTemplate.Config;
using Softwyx.SptModTemplate.Core;

namespace Softwyx.SptModTemplate.Patches;

/// <summary>Postfix on <see cref="GameWorld.OnGameStarted" /> — raid lifecycle entry point.</summary>
internal sealed class RaidStartedPatch : ModulePatch{
    protected override MethodBase GetTargetMethod(){
        return typeof(GameWorld).GetMethod(nameof(GameWorld.OnGameStarted));
    }

    [PatchPostfix]
    private static void Postfix(){
        // Standard gate: skip work when the mod is disabled (see also MenuScreenShownPatch).
        // Heavier mods may skip EnablePatch entirely in the plugin when disabled instead of patching every frame/call.
        if(!Settings.Enabled.Value) return;

        ModLifecycle.OnRaidStarted();
    }
}
