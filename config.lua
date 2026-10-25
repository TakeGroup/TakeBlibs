Config = {}

-- 'esx' = ESX Legacy (Gruppen, Jobs) | 'standalone' = nur ACE-Rechte
Config.Framework = 'esx'

-- Befehl zum Öffnen und Schließen (keine Taste, nur per Chat: /takeblibs)
Config.Command = 'takeblibs'

-- Menü-Seite: 'left' oder 'right'
Config.MenuPosition = 'left'

-- Akzentfarbe des Menüs (Auswahl, Leisten, Regler) als Hex
Config.AccentColor = '#3b82f6'

-- Rang-Level je Gruppe. Höheres Level = mehr Rechte.
-- ESX: Gruppe kommt von xPlayer.getGroup()
-- ACE: add_ace group.admin takeblibs.admin allow   (Name nach "takeblibs." = Gruppenname hier)
Config.Groups = {
    ['leitung'] = 100,
    ['dev']      = 100,
    ['verwaltung']        = 80,
    ['administrator']    = 80,
    ['moderator'] = 50,
    ['supporter'] = 20,
    ['guide'] = 20,
}
Config.UseAce = true

-- Mindest-Level pro Funktion
Config.Permissions = {
    menu       = 20,  -- Menü öffnen, alle Blips ansehen (auch deaktivierte / Job-Blips)
    teleport   = 20,  -- Zum Blip teleportieren
    create     = 50,  -- Blips erstellen und duplizieren
    edit       = 50,  -- Name, Symbol, Farbe, Größe, Position ... ändern
    visibility = 80,  -- Sichtbarkeit nach Job / Team-Rang einstellen
    delete     = 80,  -- Blips löschen
    resync     = 100, -- Sync für alle Spieler erzwingen
}

-- Speicherort der Blips (jede Änderung wird sofort gespeichert):
-- Immer:  KVP = interner FiveM-Server-Speicher, übersteht Neustarts und Ordner-Updates
-- 'auto'  = zusätzlich MySQL über oxmysql, falls vorhanden
-- 'mysql' = zusätzlich MySQL (Warnung, wenn oxmysql fehlt)
-- 'json'  = kein MySQL, nur KVP
-- data/blips.json wird immer als lesbare Sicherung mitgeschrieben.
Config.Storage = 'auto'

-- Standardwerte für neue Blips
Config.Defaults = {
    sprite     = 1,
    color      = 3,
    scale      = 0.8,
    display    = 4,
    shortRange = true,
    radius     = 0,
    category   = '',
    distance   = 300,  -- Blip erscheint erst ab dieser Entfernung in Metern (0 = immer, ganze Karte)
}

-- Auswahl "Nur in der Nähe anzeigen" im Menü (Meter, 0 = immer)
Config.Distances = { 0, 50, 100, 200, 300, 500, 750, 1000, 2000 }

-- Deckkraft von Radius-Blips (0-255)
Config.RadiusAlpha = 110

-- "Blips in der Nähe" zeigt Blips bis zu dieser Entfernung (Meter)
Config.NearbyDistance = 1000.0

-- Maximale Anzahl Blips auf dem Server
Config.MaxBlips = 500

-- Schnellauswahl Symbole (alle IDs: https://docs.fivem.net/docs/game-references/blips/)
Config.Sprites = {
    { label = 'Standard-Punkt',   sprite = 1 },
    { label = 'Haus',             sprite = 40 },
    { label = 'Polizei',          sprite = 60 },
    { label = 'Krankenhaus',      sprite = 61 },
    { label = 'Feuerwehr',        sprite = 436 },
    { label = 'Werkstatt',        sprite = 446 },
    { label = 'Tankstelle',       sprite = 361 },
    { label = 'Laden (24/7)',     sprite = 52 },
    { label = 'Kleidung',         sprite = 73 },
    { label = 'Friseur',          sprite = 71 },
    { label = 'Tattoo',           sprite = 75 },
    { label = 'Waffenladen',      sprite = 110 },
    { label = 'Bank',             sprite = 108 },
    { label = 'Geldautomat',      sprite = 277 },
    { label = 'Garage',           sprite = 357 },
    { label = 'Autohaus',         sprite = 326 },
    { label = 'Fahrzeug',         sprite = 225 },
    { label = 'Motorrad',         sprite = 226 },
    { label = 'Helikopter',       sprite = 43 },
    { label = 'Flugzeug',         sprite = 90 },
    { label = 'Boot',             sprite = 427 },
    { label = 'Taxi',             sprite = 198 },
    { label = 'Bus',              sprite = 513 },
    { label = 'LKW / Logistik',   sprite = 477 },
    { label = 'Abschlepper',      sprite = 68 },
    { label = 'Bar / Club',       sprite = 93 },
    { label = 'Büro',             sprite = 475 },
    { label = 'Lagerhaus',        sprite = 473 },
    { label = 'Casino',           sprite = 679 },
    { label = 'Fitness',          sprite = 311 },
    { label = 'Golf',             sprite = 109 },
    { label = 'Jagd',             sprite = 141 },
    { label = 'Drogen',           sprite = 140 },
    { label = 'Gang / Gebiet',    sprite = 84 },
    { label = 'Flagge',           sprite = 38 },
}

-- Farben (alle IDs: https://docs.fivem.net/docs/game-references/blips/#blip-colors)
Config.Colors = {
    { label = 'Weiß',        color = 0 },
    { label = 'Rot',         color = 1 },
    { label = 'Grün',        color = 2 },
    { label = 'Blau',        color = 3 },
    { label = 'Gelb',        color = 5 },
    { label = 'Hellrot',     color = 6 },
    { label = 'Lila',        color = 7 },
    { label = 'Pink',        color = 8 },
    { label = 'Hellorange',  color = 17 },
    { label = 'Hellgrün',    color = 25 },
    { label = 'Hellblau',    color = 26 },
    { label = 'Violett',     color = 27 },
    { label = 'Dunkelblau',  color = 29 },
    { label = 'Türkis',      color = 30 },
    { label = 'Braun',       color = 31 },
    { label = 'Grau',        color = 39 },
    { label = 'Dunkelgrau',  color = 40 },
    { label = 'Orange',      color = 47 },
    { label = 'Gold',        color = 46 },
    { label = 'Dunkelgrün',  color = 52 },
    { label = 'Cyan',        color = 54 },
    { label = 'Schwarz',     color = 72 },
    { label = 'Magenta',     color = 83 },
}

Config.DisplayModes = {
    { label = 'Karte + Minimap', display = 4 },
    { label = 'Nur Karte',       display = 3 },
    { label = 'Nur Minimap',     display = 5 },
}

Config.Radius = { 0, 25, 50, 100, 150, 200, 300, 500, 750, 1000 }
