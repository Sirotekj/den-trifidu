# Den trifidů – herní a technická dokumentace

> Zdroj pravdy pro pravidla hry, rozvržení obrazovky a formát dat.
> Při každé změně pravidel se nejdřív upraví tento dokument, pak kód.

## 1. Přehled

Tahová logická hra. Bojovník (hráč) stojí na ploše 9×9 a bojuje proti trifidům,
kteří se každý tah množí a šíří. Hráč a počítač se střídají: hráč provede jednu akci,
počítač pak nechá trifidy vyrůst a vyhodnotí výhru nebo prohru.

Jeden Godot projekt obsahuje dva programy:

| Program | Účel | Realizace |
|---|---|---|
| **DenTrifidu** | samotná hra | hlavní scéna hry, exportní preset „DenTrifidu“ |
| **EditorTrifidu** | tvorba levelů (jen pro vývoj) | samostatná hlavní scéna, exportní preset „EditorTrifidu“ |

Oba programy sdílejí stejnou herní logiku a stejný formát levelů.

## 2. Technické parametry

- **Engine:** Godot 4.7.x, GDScript.
- **Platformy:** Windows a macOS.
- **Prostředí:** 2D.
- **Základní rozlišení:** 800×600.
- **Okno:** fullscreen. Obraz se škáluje se zachováním poměru stran
  (stretch mode `canvas_items`, aspect `keep`), zbytek obrazovky je černý.
- **Ovládání:** pouze myš.
- **Jazyk hry:** čeština, s přípravou na angličtinu (viz kap. 14).

## 3. Rozvržení obrazovky

Podle návrhu `inspirace/Draft.png`. Rozměry jsou orientační a doladí se při tvorbě scény.

```
┌──────────────────────────────────────────────────────────┐
│ [Menu]            Level 1                     [O hře]    │  horní lišta (~70 px)
│ ┌───────────────────────────┐   ┌──────────────────────┐ │
│ │                           │   │ Pohyb                │ │
│ │                           │   │ Pistole           ∞  │ │
│ │     hrací plocha 9×9      │   │ Kulomet          12  │ │
│ │     pole 54 px            │   │ Plamenomet        8  │ │
│ │     = 486×486 px          │   │ Granáty           6  │ │
│ │                           │   │──────────────────────│ │
│ │                           │   │ Počet zabitých: 0    │ │
│ └───────────────────────────┘   │ Tah: 1               │ │
│                                 └──────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

- **Horní lišta:** tlačítko „Menu“, nadpis „Level N“, tlačítko „O hře“.
- **Hrací plocha vlevo:** 9×9 polí po 54 px.
- **Panel vpravo:** 5 karet (Pohyb, Pistole, Kulomet, Plamenomet, Granáty). U zbraní je
  zbývající počet použití, u pistole „∞“. Vybraná karta je zvýrazněná, karta s počtem 0
  je zašedlá. Pod kartami je „Počet zabitých“ a číslo tahu.
- **Vzhled:** kreslený styl na pozadí se strukturou papíru (inspirace: `inspirace/Draft.png`,
  `inspirace/Man.png`, `inspirace/Trifid.png`).

## 4. Hrací plocha

- Čtvercová plocha 9×9 polí, souřadnice `x` a `y` jsou 0–8, počátek vlevo nahoře.
- Každé pole obsahuje právě jedno z:
  - nic (prázdné),
  - bojovníka (na ploše je vždy právě jeden),
  - trifidy s počtem 1–9. Číslo udává počet trifidů na poli, nikdy nesmí být větší než 9.

## 5. Tah hráče

1. Hráč klikne na jednu z 5 karet v panelu. Plocha zvýrazní pole, kam lze akci použít.
2. Dokud hráč neklikne na cíl na ploše, může vybrat jinou kartu.
3. Kliknutím na platný cíl se akce provede a **tah hráče končí**.
4. Kartu s počtem 0 nejde vybrat a nereaguje na kliknutí.

**Dosah** (pistole a granát): pole je v dosahu, když vzdálenost jeho středu od středu
pole bojovníka je nejvýše R délek pole, tedy `dx² + dy² ≤ R²`.
- Pistole: R = 5.
- Granát: R = 4.

| Akce | Zvýraznění | Kliknutí | Spotřeba |
|---|---|---|---|
| **Pohyb** | prázdná pole z 8 okolních polí (jen uvnitř plochy) | bojovník se přesune na pole | neomezeně |
| **Pistole** | pole v dosahu 5 | jen na pole s trifidy: počet → 0, trifidi zmizí | neomezeně |
| **Kulomet** | až po najetí myší nad plochu: linie 4 polí (viz níže) | všechna zvýrazněná pole: počet → 0 | −1 |
| **Plamenomet** | až po najetí myší nad plochu: výseč 30° (viz níže) | všechna zvýrazněná pole: počet → 0 | −1 |
| **Granát** | jemně dosah 4, oblast 3×3 až pod kurzorem (viz níže) | všech 9 polí oblasti 3×3: počet → 0 | −1 |

**Kulomet:**
- Míří libovolným směrem: paprsek vede ze středu bojovníka přes kurzor.
- Paprsek se krokuje po hlavní ose (vodorovné nebo svislé, podle toho, ve které je
  delší) po jednom poli, celkem 4 kroky. V každém kroku je zasažené pole, ve kterém
  paprsek leží.
- Vodorovně, svisle i přesně šikmo tak zasáhne 4 pole v řadě, mezi těmito směry
  linie plynule „uhýbá“. Příklad: bojovník na (4,4) míří směrem (3,1) → zasáhne
  (5,4), (6,5), (7,5), (8,5).
- Na kraji plochy se linie zkrátí.
- Když je kurzor přímo nad bojovníkem, nic se nezvýrazní a kliknutí nic neudělá.

**Plamenomet:**
- Zasahuje kruhovou výseč s úhlem 30° a poloměrem 4 pole, měřeno od středu bojovníka.
- Osa výseče míří od středu bojovníka ke kurzoru (výseč sahá 15° na každou stranu).
- Zasažené je každé pole, do kterého výseč zasahuje aspoň malou částí (pouhý dotyk
  hranou nestačí). Technicky: pole se testuje mřížkou 6×6 bodů a stačí jeden bod ve výseči.
- Pole bojovníka se nepočítá. Na kraji plochy se výseč ořízne.
- Když je kurzor přímo nad bojovníkem, nic se nezvýrazní a kliknutí nic neudělá.

**Granát:**
- Po výběru karty se jemně zvýrazní dosah (pole, kam lze granát hodit).
- Pod kurzorem se výrazně zvýrazní oblast 3×3 se středem na poli pod kurzorem.
- Střed musí být v dosahu, jinak se nic nezvýrazní a kliknutí nic neudělá.
- Na kraji plochy se oblast ořízne.
- Granát bojovníka nezraní.

**Počet zabitých** se po každé akci zvýší o skutečný počet odebraných trifidů,
tedy o součet úbytků na všech zasažených polích.

## 6. Tah trifidů

Proběhne automaticky hned po tahu hráče (pokud hráč tahem nevyhrál):

1. **Zdvojnásobení:** všechna pole s trifidy se najednou zdvojnásobí.
2. **Strop 9:** co přesáhne 9, se stane přebytkem a pole má 9.
3. **Šíření:** přebytek se rozděluje po jednom trifidovi. Každý jde na náhodně vybrané
   sousední pole (z 8 okolních uvnitř plochy), které ještě nemá 9.
   - Pole s přebytkem se zpracovávají po řádcích shora dolů, zleva doprava.
   - Pole, kam trifid dopadne, se v tomto tahu už znovu nezdvojnásobuje.
   - Šíření je jediný způsob, jak trifidi obsazují nová pole.
   - Když už žádný soused nemá místo, zbytek přebytku zanikne.
4. **Pole bojovníka:** je mezi sousedy, kam může trifid dopadnout. Dopad na bojovníka
   znamená **prohru** (tah okamžitě končí).
5. **Přelidnění:** po šíření se každé pole s 9 trifidy, jehož všichni sousedé (uvnitř
   plochy) mají také 9, vyprázdní na 0. Vyhodnocuje se pro všechna pole najednou,
   takže souvislý blok plných polí zanikne celý. Tyto trifidy se nepočítají
   do „Počtu zabitých“.

Příklad: pole s 5 trifidy se zdvojnásobí na 10, zůstane na něm 9 a 1 trifid se rozšíří
na náhodné sousední pole.

## 7. Výhra a prohra

- **Výhra levelu:** na ploše nezbyl žádný trifid. Kontroluje se po tahu hráče.
  - Nejde-li o poslední level, zobrazí se nabídka „Další level“.
  - Po posledním levelu hráč vyhrál celou hru.
- **Prohra:** trifid při šíření vstoupí na pole bojovníka. Zobrazí se nabídka
  „Opakovat level“ (případně „Menu“).

## 8. Průběh hry a obrazovky

- **Hlavní menu:** Nová hra, Pokračovat (jen když existuje uložená hra), Konec.
- **Hra:** obrazovka podle kap. 3.
- **Menu ve hře:** pokračovat, uložit, návrat do hlavního menu.
- **O hře:** pravidla a ovládání.
- **Výhra levelu, výhra hry, prohra:** krátká obrazovka s nabídkou dalšího kroku.

## 9. Ukládání

- Jedna ukládací pozice: `user://save.json`.
- Ukládá se: aktuální level, pozice a počty všech trifidů, pozice bojovníka,
  zbývající použití kulometu, plamenometu a granátů, počet zabitých a číslo tahu.
- Uloženou hru načte volba „Pokračovat“ v hlavním menu.

## 10. Formát levelu (JSON)

- Levely leží ve složce `levels/`, soubory `level_01.json`, `level_02.json` atd.
  Pořadí levelů určuje číslo v názvu.
- Zpočátku existuje jen Level 1, další se tvoří v editoru.

```json
{
  "version": 1,
  "name": "Level 1",
  "player": { "x": 4, "y": 4 },
  "trifids": [
    { "x": 0, "y": 0, "count": 1 },
    { "x": 8, "y": 0, "count": 1 },
    { "x": 0, "y": 8, "count": 1 },
    { "x": 8, "y": 8, "count": 1 }
  ],
  "ammo": { "machine_gun": 12, "flamethrower": 8, "grenade": 6 }
}
```

**Validace:** souřadnice 0–8, `count` 1–9, každé pole nejvýše jednou, bojovník není
na poli s trifidy, munice ≥ 0.

## 11. EditorTrifidu

Nástroj jen pro vývoj, nedistribuuje se hráčům.

- Stejná plocha 9×9 jako ve hře.
- Nástroje: umístit bojovníka, umístit trifidy (výběr počtu 1–9), smazat pole.
- Nastavení počtu kulometu, plamenometu a granátů.
- Název levelu, uložit a načíst JSON.
- Tlačítko „Vyzkoušet“ spustí upravený level ve hře.
- Kontrola před uložením: přesně jeden bojovník a platná data podle kap. 10.

## 12. Grafika

Kreslený styl, černé linky na papíře. Potřebné assety:

- pozadí s texturou papíru, rámy tlačítek a karet,
- bojovník,
- trifid a štítek s číslem,
- ikony karet: pohyb, pistole, kulomet, plamenomet, granát,
- zvýraznění polí (dosah, cíl pod kurzorem),
- efekty: výstřel, plamen, výbuch, růst a šíření trifidů,
- obrazovky menu, výhry a prohry.

## 13. Zvuk a hudba (návrh)

- **Zvuky:** výstřel pistole, dávka kulometu, plamenomet, výbuch granátu, krok,
  růst a šíření trifidů, kliknutí v menu, výhra, prohra.
- **Hudba:** tlumená napjatá smyčka během hry, klidnější motiv v menu.
- **Zdroje:** knihovny s licencí CC0 nebo vlastní tvorba. Na hledání a návrh zvuků
  může později vzniknout samostatný agent.
- **Nastavení:** hlasitost hudby a zvuků zvlášť.

## 14. Lokalizace

- Teď jen čeština.
- Všechny texty pro hráče se zadávají přes překladové klíče (Godot `TranslationServer`,
  překlady v CSV), aby šla později doplnit angličtina bez změn v kódu.

## 15. Otevřené otázky

- Vyvážení: počty munice a rozmístění trifidů v jednotlivých levelech.
- Pořadí, v jakém se při šíření zpracovávají pole s přebytkem (teď po řádcích; ověřit hraním).
- Náhoda: použít pevný seed pro každý level (stejná hra při opakování), nebo náhodný?
  Ukládat stav generátoru do uložené hry?
- Animace tahů: rychlost a zda jde animace přeskočit kliknutím.
- Celkový počet levelů.
- Konkrétní zvuky a hudba.
- Ikona hry.
- Automatické ukládání (např. na začátku každého levelu)?
- Nastavení (hlasitost, jazyk) v hlavním menu?
