# Yamaha AVR for Omarchy

A keyboard-first remote for the Omarchy Quattro bar. It talks **YNCA** — Yamaha's
HTTP XML protocol on port 80 — the same path the old AV Controller phone app
uses on 2010–2014 receivers.

This is **not** MusicCast. If `http://RECEIVER/YamahaRemoteControl/desc.xml`
loads, this plugin can talk to the box.

![Yamaha AVR bar remote on RX-V677](preview.png)

## Supported devices

Anything with the **Yamaha Network Control** HTTP API
(`/YamahaRemoteControl/ctrl`). That is typical of 2010–2014 **RX-V**, **RX-A
(AVENTAGE)**, and **HTR** receivers. Later MusicCast units often still expose
YNCA; this plugin only uses that older API.

### RX-V / RX-A years that speak YNCA

| Year | RX-V | AVENTAGE | Other |
| --- | --- | --- | --- |
| 2014 | RX-V477, RX-V677, RX-V777, RX-V1077, RX-V2077, RX-V3077 | RX-A740, RX-A840, RX-A1040, RX-A2040, RX-A3040 | |
| 2013 | RX-V475, RX-V575, RX-V675, RX-V775, RX-V1075, RX-V2075, RX-V3075 | RX-A730–A3030 | HTR-4066 |
| 2012 | RX-V473, RX-V573, RX-V673, RX-V773 | RX-A720–A3020 | HTR-4065, HTR-7065 |
| 2011 | RX-V671, RX-V771, RX-V871, RX-V1071, RX-V2071, RX-V3071 | RX-A710–A3010 | HTR-6064 |
| 2010 | RX-V867, RX-V1067, RX-V2067, RX-V3067 | RX-A700–A3000 | HTR-8063 |

### Tested here

- Yamaha **RX-V575** (2013, 7.2)
- Yamaha **RX-V677** (2014, 7.2; original development target)

### Not this plugin

| Device | Why |
| --- | --- |
| MusicCast speakers, WX/WX-series, MusicCast 20/50 | Different API (`/YamahaExtendedControl/`) |
| 2020+ RX-V6A / RX-A2A / RX-A4A and similar | Prefer MusicCast; YNCA may still answer but is untested |
| Non-Yamaha AVRs | |

## Features

- Bar chip labelled **AV**
- Power, mute, and volume (absolute dB on RX-V575/RX-V677; `Val=Up` is rejected)
- Quick volume presets row: **-60 dB** (Night), **-50 dB** (Quiet), **-45 dB** (TV), **-40 dB** (Normal/Movies)
- Direct AV1, AV6, and SERVER input selection
- DLNA media library browser with now-playing metadata, transport controls, repeat, and shuffle
- Straight and 7ch Stereo
- Dedicated **Audio Controls** view:
  - **Bass & Treble** tone controls (-6.0 dB to +6.0 dB in 0.5 dB steps) with quick 0 dB reset
  - **DSP Processing toggles**: Adaptive DRC, Enhancer, and Cinema DSP 3D

## Requirements

- Omarchy Quattro
- Python 3.9 or newer (stdlib only — no pip, no venv)
- A Yamaha receiver on the LAN with Network Standby on if you want it reachable
  from sleep

The plugin runs unsandboxed inside `omarchy-shell`. Review the repository
before installing it.

## Install

```bash
omarchy plugin add https://github.com/pilotag812/omarchy-yamaha-avr.git --enable
```

Open the **AV** chip, press **D**, enter the receiver IP, and connect. Network
name is read from the box after the first successful GET.

## Controls

| Key | Action |
| --- | --- |
| O | Power On |
| X | Power Off / Standby |
| P | Power Toggle |
| M | Mute |
| - / + | Volume |
| 1 | AV1 |
| 6 | AV6 |
| E | Open SERVER media library |
| S | Straight |
| 7 | 7ch Stereo |
| A | Audio controls view |
| D | Receiver host settings |
| B | Back to remote (from Audio or Host view) |
| Q or Escape | Close / Back |

- **Bar chip (AV):** Left-click opens/closes the panel. Right-click or middle-click toggles power directly.
- **Remote buttons:** Dedicated **ON**, **OFF**, and **MUTE** buttons with active state highlights.
- **Input row:** Direct selection for AV1, AV6, and SERVER.
- **Media Server view:** Browse DLNA folders, jump through long lists with the vertical position slider, select tracks, control playback, and toggle repeat or shuffle.
- **Audio view:** Bass/Treble steppers and toggles for Adaptive DRC, Enhancer, and Cinema DSP 3D.

## Update

```bash
omarchy plugin update io.github.bjarkimg.yamaha-avr
```

## Remove

```bash
omarchy plugin remove io.github.bjarkimg.yamaha-avr
```

Optionally remove the remembered host:

```bash
rm -f "${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/settings/yamaha-avr.json"
```

## Development

```bash
omarchy plugin validate .
```

## Credits

Panel and session design follows Thomas Evans'
[Apple TV Remote for Omarchy](https://github.com/teevans/omarchy-apple-tv-remote)
and the [Android TV Remote](https://github.com/bjarkimg/omarchy-android-tv-remote)
plugin in this series.

Yamaha, YNCA, MusicCast, YPAO, and CINEMA DSP are trademarks of Yamaha
Corporation.

## License

[MIT](LICENSE)
