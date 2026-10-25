# TakeBlibs

Blip-Menü im Stil von TakeAdmin (gleiche Menü-Engine, gleiches Design, gleiches Gruppen-System).
Blips werden im Spiel erstellt, live bearbeitet und an alle Spieler synchronisiert.

## Installation

1. Ordner `TakeBlibs` in `resources` kopieren.
2. In der `server.cfg` **nach** `es_extended` (und `oxmysql`) starten:
   ```
   ensure TakeBlibs
   ```
3. Öffnen: nur per Befehl `/takeblibs` (Name in `config.lua` bei `Config.Command` änderbar). Es gibt keine Taste.

## Gruppen & Rechte

Wie bei TakeAdmin: `Config.Groups` gibt jeder Gruppe ein Level, `Config.Permissions` legt das Mindest-Level pro Funktion fest.

| Funktion     | Level | Gruppen (Standard)                      |
|--------------|-------|-----------------------------------------|
| `menu`       | 20    | guide, supporter und höher              |
| `teleport`   | 20    | guide, supporter und höher              |
| `create`     | 50    | moderator und höher                     |
| `edit`       | 50    | moderator und höher                     |
| `visibility` | 80    | administrator, verwaltung und höher     |
| `delete`     | 80    | administrator, verwaltung und höher     |
| `resync`     | 100   | leitung, dev                            |

- **ESX:** Die Gruppe kommt von `xPlayer.getGroup()`.
- **ACE** (ohne ESX oder zusätzlich): `add_ace group.admin takeblibs.administrator allow`

## Menü-Aufbau

```
Hauptmenü
├─ + Neuen Blip erstellen
├─ Alle Blips            (nach Kategorie, mit Suche)
├─ Blips in meiner Nähe  (nach Entfernung)
├─ Einstellungen         (Alle Blips immer zeigen, Nummern, Neu laden, Meine Rechte)
└─ Hilfe                 (Kurzanleitung)

Blip auswählen
├─ Aussehen              Name, Symbol, Farbe, Größe, Kreis, Kategorie (+ Profi-Optionen)
├─ Wer sieht den Blip?   An/Aus, Rang, Jobs
├─ Position              Hinteleportieren, Wegpunkt, Verschieben, Koordinaten kopieren
├─ Kopie erstellen
└─ Blip löschen
```

Jeder Eintrag hat unten im Menü eine kurze Erklärung.

## Funktionen

- Blip an der eigenen Position erstellen, duplizieren und löschen
- Name, Symbol, Farbe, Größe, Anzeige (Karte/Minimap), Short Range, Radius-Kreis und Kategorie
- Live-Vorschau: Mit ←/→ ändert sich der Blip sofort auf der Karte, Enter speichert
- Sichtbarkeit:
  - **Sichtbar für:** alle Spieler oder nur Team ab einer Gruppe aus `Config.Groups`
  - **Jobs:** nur für bestimmte ESX-Jobs
  - Gefiltert wird **auf dem Server**: Spieler bekommen versteckte Blips gar nicht erst zugeschickt.
- Blip deaktivieren (bleibt gespeichert, sichtbar nur in der Admin-Ansicht)
- Admin-Ansicht: Bei offenem Menü sieht das Team alle Blips. Optional bleibt sie dauerhaft an, auch mit `#ID` im Namen.
- Liste nach Kategorie mit Suche, „Blips in der Nähe“ mit Entfernung
- Teleport, Wegpunkt setzen, Position auf eigene Position oder Wegpunkt setzen, Koordinaten kopieren
- Discord-Logs (`server/sv_config.lua`)

## Speicherung

Jede Änderung wird **sofort** gespeichert:

- **Immer im KVP**, dem internen Speicher des FiveM-Servers. Er bleibt bei Server- und Script-Neustarts erhalten und auch dann, wenn du den Ordner neu reinkopierst.
- **Zusätzlich in MySQL** (Tabelle `takeblibs_blips`), wenn `oxmysql` läuft (`Config.Storage = 'auto'`).
- `data/blips.json` wird als lesbare Sicherung mitgeschrieben.

Beim Start steht in der Server-Konsole, wie viele Blips aus welcher Quelle geladen wurden:
`[TakeBlibs] 12 Blip(s) geladen aus KVP. Speichern: MySQL + KVP`

## Nur in der Nähe anzeigen

Jeder Blip erscheint erst, wenn man nah genug dran ist. Der Standard steht in `Config.Defaults.distance` (300 m, `0` = immer auf der ganzen Karte).
Pro Blip kannst du das im Menü unter **Wer sieht den Blip? → Nur in der Nähe zeigen** ändern.
Bei offenem Menü sieht das Team alle Blips, damit man sie zum Bearbeiten findet.

## Banner

Ohne Bild wird ein eingebautes Banner im TakeAdmin-Stil angezeigt. Für ein eigenes Banner einfach `html/banner.png` ablegen (Format 862 × 216).

## Konsole

- `tb_list [Suche]`: alle Blips auflisten
- `tb_resync`: Blips erneut an alle Spieler senden
