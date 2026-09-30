# Yamaha AVR for Omarchy

A keyboard-friendly remote for Yamaha AV receivers in the Omarchy Quattro bar.
It communicates over Yamaha Network Control (YNCA), the receiver's HTTP XML API.

[English](#english) · [Русский](#русский)

## English

### Features

- Power, mute, volume in 0.5 dB steps, and four quick volume presets: −60, −50, −45, and −40 dB.
- Receiver inputs on the main remote can be chosen in **INPUTS**. The available inputs are read from the receiver; AV1, AV6, and SERVER are selected by default.
- The **SERVER** view loads every item in the current DLNA folder automatically, eight items at a time. The list scrolls locally, so moving through a loaded folder does not send a command for each step.
- Folder and track selection, playback controls, repeat, shuffle, and now-playing metadata.
- Straight and 7ch Stereo modes; bass, treble, Adaptive DRC, Enhancer, and Cinema DSP 3D controls.

### Compatibility and requirements

The receiver must expose Yamaha Network Control at `/YamahaRemoteControl/ctrl`.
You can check whether `http://RECEIVER_IP/YamahaRemoteControl/desc.xml` responds in a browser. The plugin has been used with Yamaha RX-V575 and RX-V677. Other RX-V, RX-A, and HTR models may expose the same API, but their available inputs and audio controls can differ. MusicCast-only devices using `/YamahaExtendedControl/` are not supported.

You need Omarchy Quattro, Python 3.10 or newer (standard library only), and a receiver reachable on your private IPv4 LAN. Enable **Network Standby** on the receiver if you want to reach it while it is in standby.

### Install and set up

```bash
omarchy plugin add https://github.com/pilotag812/omarchy-yamaha-avr.git --enable
```

Open the **AV** widget, press **D**, enter the receiver's IP address, and connect. Open **INPUTS** (or press **I**) to tick the sources you want on the main remote. The selection and receiver address are saved locally.

### Controls

| Key | Main remote | SERVER view |
| --- | --- | --- |
| O / X / P | Power on / standby / toggle | Stop (X) / play or stop (P) |
| M | Toggle mute | — |
| − / + | Volume down / up | — |
| 1 / 6 | Select AV1 / AV6 | — |
| E | Open SERVER | Open selected folder or track |
| W / S | — | Move selection in the loaded list |
| H / G | — | Back / home in the media library |
| V / N | — | Previous / next track |
| R | — | Reload the current folder |
| A / I / D | Audio controls / input selection / receiver address | — |
| S / 7 | Straight / 7ch Stereo | — |
| B | Return to the main remote from another view | Return to the main remote |
| Q / Escape | Close the panel | Return to the main remote |

The SERVER view also has buttons for repeat and shuffle. Left-click the **AV** bar widget to open or close the panel; right-click or middle-click it to toggle receiver power.

### Update, remove, and validate

```bash
omarchy plugin update io.github.bjarkimg.yamaha-avr
omarchy plugin validate ~/.config/omarchy/plugins/io.github.bjarkimg.yamaha-avr
omarchy plugin remove io.github.bjarkimg.yamaha-avr
```

The receiver address and selected inputs are stored in `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/settings/yamaha-avr.json`. Removing the plugin does not remove this file automatically.

## Русский

### Возможности

- Питание, отключение звука, регулировка громкости с шагом 0,5 дБ и четыре быстрых уровня: −60, −50, −45 и −40 дБ.
- Источники на главном экране выбираются галочками в разделе **INPUTS**. Список доступных входов плагин получает от ресивера. По умолчанию выбраны AV1, AV6 и SERVER.
- Экран **SERVER** автоматически загружает все элементы текущей папки DLNA порциями по восемь. Уже загруженный список прокручивается локально, без команды ресиверу на каждый шаг.
- Открытие папок и треков, управление воспроизведением, повтором и перемешиванием, отображение текущего трека.
- Режимы Straight и 7ch Stereo; настройки низких и высоких частот, Adaptive DRC, Enhancer и Cinema DSP 3D.

### Совместимость и требования

Ресивер должен поддерживать Yamaha Network Control по адресу `/YamahaRemoteControl/ctrl`. Проверить это можно, открыв в браузере `http://IP_РЕСИВЕРА/YamahaRemoteControl/desc.xml`. Плагин использовался с Yamaha RX-V575 и RX-V677. У других моделей RX-V, RX-A и HTR может быть тот же API, но набор входов и звуковых настроек может отличаться. Устройства, работающие только через MusicCast API `/YamahaExtendedControl/`, не поддерживаются.

Нужны Omarchy Quattro, Python 3.10 или новее (только стандартная библиотека) и ресивер, доступный в частной сети IPv4. Чтобы ресивер отвечал в режиме ожидания, включите на нём **Network Standby**.

### Установка и настройка

```bash
omarchy plugin add https://github.com/pilotag812/omarchy-yamaha-avr.git --enable
```

Откройте виджет **AV**, нажмите **D**, введите IP-адрес ресивера и подключитесь. В разделе **INPUTS** (клавиша **I**) отметьте источники, которые нужно показывать на главном экране. Адрес ресивера и выбор источников сохраняются локально.

### Управление

| Клавиша | Главный экран | Экран SERVER |
| --- | --- | --- |
| O / X / P | Включить / перевести в режим ожидания / переключить питание | Остановить (X) / воспроизвести или остановить (P) |
| M | Включить или отключить звук | — |
| − / + | Уменьшить / увеличить громкость | — |
| 1 / 6 | Выбрать AV1 / AV6 | — |
| E | Открыть SERVER | Открыть выбранную папку или трек |
| W / S | — | Переместить выделение по загруженному списку |
| H / G | — | Назад / в начало медиатеки |
| V / N | — | Предыдущий / следующий трек |
| R | — | Обновить текущую папку |
| A / I / D | Настройки звука / выбор входов / адрес ресивера | — |
| S / 7 | Режим Straight / 7ch Stereo | — |
| B | Вернуться на главный экран | Вернуться на главный экран |
| Q / Escape | Закрыть панель | Вернуться на главный экран |

На экране SERVER есть отдельные кнопки повтора и перемешивания. Щелчок левой кнопкой по виджету **AV** открывает или закрывает панель; щелчок правой или средней кнопкой переключает питание ресивера.

### Обновление, удаление и проверка

```bash
omarchy plugin update io.github.bjarkimg.yamaha-avr
omarchy plugin validate ~/.config/omarchy/plugins/io.github.bjarkimg.yamaha-avr
omarchy plugin remove io.github.bjarkimg.yamaha-avr
```

Адрес ресивера и выбранные входы хранятся в `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/settings/yamaha-avr.json`. При удалении плагина этот файл остаётся.

## Credits / Благодарности

The panel and session design draws on [Apple TV Remote for Omarchy](https://github.com/teevans/omarchy-apple-tv-remote) and [Android TV Remote](https://github.com/bjarkimg/omarchy-android-tv-remote). / Дизайн панели и сеанса основан на этих проектах.

Yamaha, YNCA, MusicCast, YPAO, and CINEMA DSP are trademarks of Yamaha Corporation. / Указанные названия являются товарными знаками Yamaha Corporation.

Licensed under [MIT](LICENSE). / Лицензия — [MIT](LICENSE).
