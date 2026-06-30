# Softwyx SPT Mod Template

Starter kit for **SPT 4.x** client mods (BepInEx + Harmony via `SPT.Reflection.Patching`).

This repository is the template **and** a runnable example mod. Build it to verify your game paths, or run the wizard to
scaffold a new project.

## Quick start (try the example)

1. Copy `Directory.Build.props.user.example` to `Directory.Build.props.user` and set `TarkovDir` to your SPT install.
2. Validate your install (optional):

   ```powershell
   .\scripts\Validate-Install.ps1
   ```

3. Build:

   ```powershell
   dotnet build -c Debug
   ```

   Debug builds deploy the DLL to `BepInEx/plugins/<AssemblyName>/` and remove the mod config file so defaults reload on
   next launch.

4. Launch SPT. You should see a BepInEx log when the plugin loads and a **message dialogue** once on the main menu.

## Create a new mod (wizard)

From this folder:

```powershell
.\New-SptMod.ps1
```

The wizard asks for mod name, **author prefix**, **GUID prefix**, display title, output folder, **TarkovDir** (
validated), and whether to run `git init`. It runs **Validate-Install** on the new project when finished.

Non-interactive:

```powershell
.\New-SptMod.ps1 -Name MyRaidMod -OutputDir C:\Dev\SPT-MyRaidMod `
  -TarkovDir "D:\Games\Escape from Tarkov" -AuthorPrefix Acme -GuidPrefix com.acme -GitInit -NonInteractive
```

| Parameter         | Description                                                          |
|-------------------|----------------------------------------------------------------------|
| `-Name`           | PascalCase mod name (e.g. `MyRaidMod`)                               |
| `-AuthorPrefix`   | Namespace segment (default `Softwyx` → `Acme.MyRaidMod`)             |
| `-GuidPrefix`     | Plugin GUID prefix (default `com.softwyx` → `com.acme.mymod`)        |
| `-OutputDir`      | Folder to create (must not exist)                                    |
| `-TarkovDir`      | SPT install path (required; written to `Directory.Build.props.user`) |
| `-DisplayName`    | Human-readable plugin title                                          |
| `-LogPrefix`      | 2–6 character BepInEx log prefix                                     |
| `-GitInit`        | Run `git init` and an initial commit                                 |
| `-NonInteractive` | Skip prompts; requires `-Name`, `-OutputDir`, and `-TarkovDir`       |

## Versioning

Version lives in the `.csproj` only. Each build bumps the patch segment and regenerates `src/PluginInfo.Version.g.cs`
for `[BepInPlugin(..., version)]`. Edit major/minor in the `.csproj`. Disable auto-bump (just invert the default value
in `Softwyx.SptModTemplate.csproj` to take control over versioning):

```powershell
dotnet build -p:IncrementVersionOnBuild=false
```

## Release ZIP

```powershell
dotnet build -c Package
```

Produces `Package/<AssemblyName>-<version>.zip` (WinRAR or 7-Zip required). Release and Package builds are
Authenticode-signed by default (see **Code signing** below).

## Code signing

Release and Package configurations sign the DLL after build via `Directory.Build.targets` → `scripts/SignAssembly.ps1`.

| Setting                      | Default                                                                   |
|------------------------------|---------------------------------------------------------------------------|
| `SignAssembly`               | `true`                                                                    |
| `SignAssemblyConfigurations` | `Release;Package`                                                         |
| `SigningCertSubject`         | `CN=Softwyx.SptModTemplate` (override per mod in `Directory.Build.props`) |

Certificate resolution: PFX file (if configured) → cert store by subject → auto-create self-signed cert. Set
`SignAssembly=false` in `Directory.Build.props.user` to skip. See `Directory.Build.props.user.example` for PFX
path/password options. Never commit `*.pfx` or `certs/`.

## Example mod details

- **Menu:** patch on `EFT.UI.MenuScreen.Show` → welcome dialogue via `ItemUiContext.ShowMessageWindow`
- **Raid:** patch on `GameWorld.OnGameStarted` → log-only stub (enabled gate on `Settings.Enabled`)
- **Dependencies:** `[BepInDependency("com.SPT.core", "4.0.0")]` plus commented optional examples in the plugin class

## Localization

Client strings live in `locales/<id>.json` (e.g. `locales/en.json`). Keys must use your mod prefix — the template uses
`sptmodtemplate_*` (see `Localization/LocaleKeys.KeyPrefix`).

| Type                                                    | Use                                                                                                            |
|---------------------------------------------------------|----------------------------------------------------------------------------------------------------------------|
| `LocaleLoader.Get(key)`                                 | Merged game locale + mod pack (dialogs, formatted strings)                                                     |
| `LocaleLoader.TryGet(key)`                              | Mod-pack lookup only; returns `null` when the key is missing                                                   |
| `GameLocaleAccess.TryLocalize(key)`                     | Vanilla / SPT game locale via the game's `Localized()` string extension (same path as `ItemLocale`)            |
| `ItemLocale.Name(templateId)` / `ShortName(...)`        | EFT item display names via the game's `.Localized()` extension                                                 |
| `DisplayLabelResolver.Resolve(...)`                     | UI labels: game locale → mod fallback → raw id                                                                 |
| `DisplayLabelResolver.ResolveFieldName(...)`            | PascalCase field names → camelCase game keys → mod fallback                                                    |
| `LocalizedTextView.BindKey(transform, key, labelChild)` | UI with `EFT.UI.LocalizedText` + TMP                                                                           |
| `LocaleApplicationLanguagePatch`                        | Merges JSON when `LocaleManagerClass.UpdateApplicationLanguage` runs                                           |
| `LocaleLoader`                                          | Validates all `locales/*.json`, builds a catalogue, merges into the game; runtime apply uses `ContainsCulture` |

On `Awake`, `PreloadDefaultLocale()` runs first — if it fails, no patches are enabled. Do not patch `UpdateLocales` (can
deadlock startup). Debug builds copy `locales/` next to the DLL under `BepInEx/plugins/<AssemblyName>/locales/`.

Add packs as `locales/fr.json`, etc. Missing keys fall back to `en.json`. For UI built in code, prefer `LocalizedText`
with a key over hard-coded strings.

### Game locale vs mod locale

- **Persist codenames** in saved data (`bigmap`, `AmmoUsed`, exit reason ids). **Resolve labels in UI only** when
  rendering player-facing text.
- **Game keys first** via `GameLocaleAccess` — uses the game's `Localized()` extension (same strings the client
  uses, e.g. `"bigmap"` → `"Customs"`). Browse `SPT/SPT_Data/database/locales/global/en.json` for key names.
- **Mod keys second** — your prefixed entries in `locales/*.json` for copy the game does not own (feature titles, custom
  counters, fallbacks).
- **Logs stay English/raw** — do not localize BepInEx output; use `DisplayLabelResolver` / `LocaleLoader` only for
  player UI. This guarantees that most people can read the logs and will save you a lot of unneeded bug reports.

The welcome dialogue demonstrates `DisplayLabelResolver.Resolve("bigmap", LocaleKeys.ExampleMapFallback)` in
`Core/ModLifecycle.cs`.

## Interop (obfuscated game API)

For a readable and maintainable code, never use decompiler names (`GClass*`, `Dictionary_*`, …) in feature code. Confine them under `src/Interop/`.

This template uses the following segregation logic:

| File                   | Purpose                                                                       |
|------------------------|-------------------------------------------------------------------------------|
| `GameTypeAliases.cs`   | `global using` aliases for obfuscated **types** (e.g. `MenuScreenController`) |
| `GameAssemblyNames.cs` | Obfuscated **field/method** name strings for reflection                       |
| `GameMemberAccess.cs`  | `GetField` / `GetProperty` via Harmony `AccessTools`                          |
| `GameLocaleAccess.cs`  | Read merged game locale via `Localized()` (same as `ItemLocale`)              |

## Configuration UI

BepInEx Configuration Manager custom drawers live in `src/Config/`:

| Helper                                 | Use for                                                |
|----------------------------------------|--------------------------------------------------------|
| `ConfigFloatUi.Attributes(...)`        | Float sliders with decimal precision and step snapping |
| `ConfigIntegralUi.IntAttributes(...)`  | Int sliders with step snapping                         |
| `ConfigIntegralUi.LongAttributes(...)` | Long sliders with step snapping                        |

See `Settings.cs` for float/int/long examples. Call `ConfigFloatUi.SnapEntries(...)` after bind to quantize existing
saved values.

## Scripts

| Script                         | Purpose                                              |
|--------------------------------|------------------------------------------------------|
| `New-SptMod.ps1`               | Interactive wizard to scaffold a new mod             |
| `scripts/Validate-Install.ps1` | Check `TarkovDir` and required game/SPT DLLs         |
| `scripts/IncrementVersion.ps1` | Patch bump + `PluginInfo.Version.g.cs` (MSBuild)     |
| `scripts/package.ps1`          | Release ZIP (`Package` configuration)                |
| `scripts/SignAssembly.ps1`     | Authenticode signing (MSBuild `SignAssembly` target) |
| `scripts/ReencodeUtf8.ps1`     | Normalize UTF-8 no BOM + LF line endings             |

## Attribution

Scaffolded projects keep `TEMPLATE-ATTRIBUTION.md` and a README credit line. See `LICENSE`.
