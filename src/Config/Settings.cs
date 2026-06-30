namespace Softwyx.SptModTemplate.Config;

internal static class Settings{
    private const string GeneralSection = "1. General";

    public static  ConfigEntry<bool>  Enabled;
    public static  ConfigEntry<bool>  ShowWelcomeDialog;
    private static ConfigEntry<float> ExampleScalar;
    private static ConfigEntry<int>   ExampleCount;
    private static ConfigEntry<long>  ExampleThreshold;

    private static readonly List<ConfigEntryBase> Entries = [];

    public static void Init(ConfigFile config){
        Entries.Clear();

        Enabled = config.Bind(
                              GeneralSection,
                              "Enabled",
                              true,
                              new ConfigDescription("Master toggle for the mod.", null, Basic())
                             );

        ShowWelcomeDialog = config.Bind(
                                        GeneralSection,
                                        "Show welcome dialog",
                                        true,
                                        new ConfigDescription(
                                                              "Show a message window once when the main menu appears.",
                                                              null,
                                                              Basic()
                                                             )
                                       );

        ExampleScalar = config.Bind(
                                    GeneralSection,
                                    "Example scalar",
                                    1f,
                                    new ConfigDescription(
                                                          "Sample float with slider and editable field.",
                                                          new AcceptableValueRange<float>(0f, 10f),
                                                          FloatUi(false, 2, 0.1f)
                                                         )
                                   );

        ExampleCount = config.Bind(
                                   GeneralSection,
                                   "Example count",
                                   5,
                                   new ConfigDescription(
                                                         "Sample int with slider and editable field.",
                                                         new AcceptableValueRange<int>(1, 20),
                                                         IntUi(false, 1)
                                                        )
                                  );

        ExampleThreshold = config.Bind(
                                       GeneralSection,
                                       "Example threshold",
                                       100000L,
                                       new ConfigDescription(
                                                             "Sample long with slider and editable field.",
                                                             new AcceptableValueRange<long>(0L, 1_000_000L),
                                                             LongUi(false, 10000L)
                                                            )
                                      );

        Entries.Add(Enabled);
        Entries.Add(ShowWelcomeDialog);
        Entries.Add(ExampleScalar);
        Entries.Add(ExampleCount);
        Entries.Add(ExampleThreshold);

        ConfigFloatUi.SnapEntries(Entries, 2, 0.1f);
    }

    private static ConfigurationManagerAttributes Basic(){
        return new ConfigurationManagerAttributes{
                                                     Order = 0
                                                 };
    }

    private static ConfigurationManagerAttributes FloatUi(bool isAdvanced, int decimals, float step){
        return ConfigFloatUi.Attributes(isAdvanced, decimals, step);
    }

    private static ConfigurationManagerAttributes IntUi(bool isAdvanced, int step){
        return ConfigIntegralUi.IntAttributes(isAdvanced, step);
    }

    private static ConfigurationManagerAttributes LongUi(bool isAdvanced, long step){
        return ConfigIntegralUi.LongAttributes(isAdvanced, step);
    }
}
