# Grafika – seznam assetů

Všechny obrázky jsou ve **2× rozlišení** hry (hra 800×600, pole 54 px → obrázky pro pole 108 px,
celá obrazovka 1600×1200). Ve hře se kreslí zmenšené.

Výřezy se generují skriptem `tools/graphics/cut_draft.gd`:

```
godot --headless --path . --script res://tools/graphics/cut_draft.gd
godot --headless --path . --import
```

Souřadnice jsou v pixelech zdrojového obrázku (Draft.png 1448×1086, Man.png 1024×1536).
Výřezy z Draftu se zvětšují poměrem 1600/1448 ≈ 1,105.
Postavy, ikony a štítek: papír spojený s okrajem výřezu je průhledný, papír uvnitř obrysu
zůstává neprůhledný (postava zakryje mřížku). Rámečky: průhledné je všechno kromě tahů tuší.

| Soubor | Zdroj | Velikost | Stav |
|---|---|---|---|
| `background/paper.jpg` | celý Draft.png zvětšený na 1600×1200; tlačítka, nadpis, plocha, karty a texty přemalované generovanou texturou papíru (šum podle barvy papíru z Draftu, oblast 950,940 330×40), natrhaný okraj zůstal z Draftu | 1600×1200 (JPG, bez průhlednosti) | dočasný výřez |
| `characters/fighter.png` | Draft.png, bojovník uprostřed plochy, 477,463 118×174, smazané čáry mřížky | 108×108 | dočasný výřez |
| `characters/trifid.png` | Draft.png, trifid vlevo nahoře, 137,188 141×175, bez štítku s číslem a mřížky | 108×108 | dočasný výřez |
| `ui/trifid_label.png` | Draft.png, štítek trifida vlevo nahoře, 244,287 53×62, číslice „1“ smazaná, vnitřek zadaný polygonem (obrys je vlevo dole otevřený) | 59×69 | dočasný výřez |
| `ui/card_frame.png` | Draft.png, karta „Pistole“, 950,212 470×133; obsah smazaný, mezery v horním/dolním okraji doplněné kopiemi čistých kusů okraje téže karty | 519×147 | dočasná náhrada (horní okraj je místy přerušovaný) |
| `ui/button_frame.png` | Draft.png, tlačítko „Menu“, 45,32 253×116, text smazaný; používá se pro všechna tlačítka | 280×128 | dočasný výřez |
| `icons/icon_pistol.png` | Draft.png, karta Pistole, 1006,225 114×105 | 126×116 | dočasný výřez |
| `icons/icon_machine_gun.png` | Draft.png, karta Kulomet, 965,360 183×108 | 202×119 | dočasný výřez |
| `icons/icon_flamethrower.png` | Draft.png, karta Plamenomet, 966,512 292×128 | 323×141 | dočasný výřez |
| `icons/icon_grenade.png` | Draft.png, karta Granáty, 1004,676 100×112 | 110×124 | dočasný výřez |
| `icons/icon_move.png` | Man.png, levá bota bojovníka, 75,1238 320×212 (v Draftu ikona pohybu není) | 150×100 | **dočasná náhrada** |
| `ui/game_theme.tres` | téma hry: rámečky tlačítek a karet (StyleBoxTexture), tmavé písmo, panel dialogu | – | finální (ladit podle nových assetů) |

## Použití ve hře
- `scenes/game/game.tscn`: pozadí `TextureRect` s `paper.jpg`, téma `game_theme.tres` na kořeni.
- `scripts/game/board_view.gd`: bojovník a trifid jako textury (o 12 % větší než pole, stojí na
  spodní hraně), štítek s počtem vpravo dole, mřížka kreslená kódem (lehce zvlněné čáry).
  Když textura chybí, kreslí se původní kolečka.
- `scripts/game/action_panel.gd`: karty = `Button` s variantou tématu `CardButton`, ikona vlevo,
  název nahoře, počet vpravo dole. Vybraná karta: žlutý podklad s rámečkem a červenohnědý rám,
  nepoužitelná karta: celá průhledná na 30 %.

## Co chybí / k dodání
- Ikona pohybu (stopy nebo bota), ~200×120 px, kresba tuší na bílém.
- Čistý prázdný rámeček karty ~520×150 px a tlačítka ~280×130 px (bez textu, souvislý obrys).
- Štítek pro číslo trifida s uzavřeným obrysem, ~60×70 px.
- Bojovník a trifid nakreslení přímo pro pole 108×108 (výřezy z Draftu mají jen ~120×175 px).
- Papír bez obsahu v 1600×1200 (teď je střed papíru generovaný šumem).
- Písmo: ručně psané s českou diakritikou (např. Caveat nebo Patrick Hand, obě OFL) – nestaženo.
