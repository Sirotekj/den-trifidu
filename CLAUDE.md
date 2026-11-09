# CLAUDE.md – pravidla pro práci na projektu „Den trifidů“

## Projekt
- 2D tahová hra v Godot 4.7 (GDScript), základní rozlišení 800×600, ovládání myší.
- Jeden projekt, dvě hlavní scény: **DenTrifidu** (hra) a **EditorTrifidu** (editor levelů).
- `GAME_DESIGN.md` je zdroj pravdy pro pravidla a data. Při změně pravidel ho aktualizuj
  dřív než kód. Když narazíš na rozpor nebo nejasnost, zeptej se.

## Postup
- Nejdřív plán ke schválení, teprve potom kód.
- Pracuj po malých krocích, které jdou spustit a ověřit.
- **Git: commituj jen na výslovný pokyn.** Před commitem se zeptej.

## Jazyk
- Komunikace a dokumentace česky.
- Kód anglicky: názvy souborů, tříd, funkcí, proměnných i komentáře.
- Texty pro hráče nikdy přímo v kódu, jen přes překladové klíče (příprava na angličtinu).

## Kód
- GDScript se statickými typy (`var count: int`, `func f() -> void`).
- Herní logika (plocha, tahy, šíření, výhra/prohra) je čistý kód oddělený od zobrazení,
  aby ji sdílela hra i editor a šla testovat bez scény.
- Levely jsou JSON ve `levels/`, uložená hra v `user://save.json` (formát v `GAME_DESIGN.md`).
- Náhodu řeš přes jednu instanci `RandomNumberGenerator`, ne globální `randi()`.

## Struktura složek (návrh)
- `scenes/` – scény (`game/`, `editor/`, `ui/`)
- `scripts/` – skripty (`logic/` pro herní pravidla)
- `assets/` – grafika, zvuky, fonty
- `levels/` – JSON levely
- `inspirace/` – návrhy a skici, nejsou součástí hry
- Needituj `.godot/` (generuje se automaticky).
