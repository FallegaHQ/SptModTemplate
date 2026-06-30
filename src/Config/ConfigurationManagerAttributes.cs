// ReSharper disable All
// Display hints for BepInEx ConfigurationManager (https://github.com/BepInEx/BepInEx.ConfigurationManager)

#pragma warning disable 0169, 0414, 0649

internal sealed class ConfigurationManagerAttributes{
    public delegate void CustomHotkeyDrawerFunc(
        BepInEx.Configuration.ConfigEntryBase setting, ref bool isCurrentlyAcceptingInput
    );

    public bool?  Browsable;
    public string Category;

    public System.Action<BepInEx.Configuration.ConfigEntryBase> CustomDrawer;

    public CustomHotkeyDrawerFunc      CustomHotkeyDrawer;
    public object                      DefaultValue;
    public string                      Description;
    public string                      DispName;
    public bool?                       HideDefaultButton;
    public bool?                       HideSettingName;
    public bool?                       IsAdvanced;
    public System.Func<object, string> ObjToStr;
    public int?                        Order;
    public bool?                       ReadOnly;
    public bool?                       ShowRangeAsPercent;
    public System.Func<string, object> StrToObj;
}
