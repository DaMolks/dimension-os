# Editions

Every Dimension OS machine declares one edition via:

```nix
dimension.edition = "<edition>";
```

The edition is the single knob that activates the right set of modules by default. All defaults can be overridden per-host.

---

## Edition Reference

### `desktop`

General-purpose workstation with the full Dimension desktop.

| Module | Default |
|--------|---------|
| `dimension.desktop` | enabled |
| `dimension.kde` | enabled |
| `dimension.apps` | enabled |
| `dimension.theme` | enabled |
| `dimension.sddm` | enabled |
| `dimension.plymouth` | enabled |
| `dimension.node` | enabled |
| `dimension.network` | enabled |
| `dimension.network.avahi` | enabled |
| `dimension.storage` | enabled |
| `dimension.remote` | enabled |
| `dimension.dimensionSettings` | enabled |
| `dimension.hub` | disabled |
| `dimension.wireguard` | disabled |

---

### `laptop`

Same as `desktop` plus power and input tuning.

Additional system config:

- `hardware.bluetooth.enable = true`
- `services.fprintd.enable = true`
- `services.auto-cpufreq.enable = true`
- `services.libinput.enable = true` with natural scrolling and tap-to-click
- `services.geoclue2.enable = true`
- `services.localtimed.enable = true`
- `services.thermald.enable = true`
- `hardware.sensor.iio.enable = true`

---

### `gaming`

Desktop stack plus gaming-specific tools and optimisations.

Additional system config:

- `hardware.opengl.enable = true` with 32-bit support
- `hardware.xone.enable = true`
- `powerManagement.cpuFreqGovernor = "performance"`
- `programs.steam.enable = true` with gamescope session
- `programs.gamemode.enable = true`
- Extra packages: `gamescope`, `mangohud`
- Panel: panel auto-hides (`panelVisibility = 1`)
- `dimension.remote.sunshine.enable = true` by default

---

### `workstation`

Desktop stack plus developer tools and services.

Additional system config:

- `virtualisation.docker.enable = true`
- `services.flatpak.enable = true`
- `services.printing.enable = true`
- Extra packages: `libreoffice`, `gimp`, `inkscape`, `vscode`, `git`, `htop`, `tmux`, `neovim`, `ripgrep`, `fd`, `jq`
- Extra fonts: `JetBrains Mono`, `nerd-fonts`
- Main user added to `docker` group

`dimension.dimensionSettings.enable = true` by default.

---

### `home-theatre`

Minimal desktop without standard apps. Panel auto-hides fully (`panelVisibility = 2`).

| Module | Default |
|--------|---------|
| `dimension.desktop` | enabled |
| `dimension.kde` | enabled |
| `dimension.apps` | **disabled** |
| `dimension.homeTheatre` | enabled |

---

### `print-station`

Dedicated printing machine.

Additional system config:

- `services.printing.enable = true` with gutenprint and hplip drivers
- `services.avahi.enable = true` with mDNS
- `cups-filters`, `ghostscript`
- `dimension.storage.samba.enable = true` by default for Windows-compatible share

---

### `server`

Desktop-capable server for local infrastructure management.

| Module | Default |
|--------|---------|
| `dimension.desktop` | enabled |
| `dimension.hub` | **enabled** |
| `dimension.node` | enabled |
| All other desktop modules | same as `desktop` |

Use this edition when the machine hosts the Dimension Hub and needs a local admin UI.

---

### `server-headless`

No desktop. Hub/Node for headless infrastructure.

| Module | Default |
|--------|---------|
| `dimension.desktop` | disabled |
| `dimension.kde` | disabled |
| `dimension.apps` | disabled |
| `dimension.theme` | disabled |
| `dimension.sddm` | disabled |
| `dimension.plymouth` | disabled |
| `dimension.network.avahi` | disabled |
| `dimension.node` | enabled |
| `dimension.storage` | enabled |
| `dimension.remote` | enabled |
| `dimension.hub` | disabled (opt-in) |

This is the default edition when no edition is declared.

---

## Adding An Edition

Editions are defined in `modules/profiles/default.nix`. To add one:

1. Add the name to the `lib.types.enum` list.
2. Add a `lib.mkIf (cfg.edition == "<name>") { ... }` block with any additional system config.
3. The default module flags at the top of `config = lib.mkMerge [...]` cover all editions via the existing conditions — adjust them if the new edition needs different defaults.

---

## Overriding Edition Defaults

Any edition default can be overridden in the host config:

```nix
dimension.edition = "desktop";
dimension.wireguard = {
  enable = true;
  privateKeyFile = "/etc/dimension/secrets/wg-private-key";
  address = "10.100.0.2/24";
  openFirewall = true;
};
```

Use `lib.mkForce` when overriding something the profiles module sets with `lib.mkDefault`.
