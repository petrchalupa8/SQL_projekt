# Informace o výstupních datech a kvalitě datových sad

Tento dokument detailně popisuje stav výstupních datových sad, jejich datovou kvalitu, identifikované anomálie a místa, kde chybí hodnoty (NULL záznamy).

---

## 1. Chybějící hodnoty (Missing Data / NULLs)

Při zpracování a propojování primárních datových sad bylo nutné ošetřit několik významných výpadků a nesrovnalostí v datech ČSÚ:

### A. Oblast cen potravin (Sada Ceny)
* **Chybějící roky u specifických komodit:** Některé potraviny nebyly sledovány po celou dobu (2006–2018). Například u některých druhů zeleniny či specifických mléčných výrobků chyběla data pro roky 2006 a 2007 z důvodu změny metodiky spotřebního koše ČSÚ.
* **Řešení v projektu:** Tyto komodity byly z plošného meziročního porovnání vyřazeny, aby nedošlo ke zkreslení průměrů. Analýza pracovala pouze s plně validními řadami (jako je chléb, mléko, eidam, brambory, banány).

### B. Oblast mezd (Sada Mzdy)
* **Neklasifikovaná odvětví:** V primárních datech se vyskytovaly záznamy s chybějícím nebo neznámým kódem odvětví (označeno jako "Nerozlišeno" nebo NULL).
* **Řešení v projektu:** Tyto řádky byly při čištění dat striktně odfiltrovány (`WHERE odvetvi IS NOT NULL`), protože nebylo možné určit jejich ekonomický kontext. Analýza se zaměřila výhradně na 19 standardizovaných odvětví podle CZ-NACE.

### C. Propojení dat (JOIN operace)
* Při tvorbě finální datové sady vznikaly potenciální NULL hodnoty v letech, kde se nekryla data cen (která v některých okrajových měsících chyběla) s daty mezd (která jsou vykazována kvartálně/ročně). Všechny výstupní tabulky byly ošetřeny tak, aby obsahovaly pouze kompletní průniky (`INNER JOIN`).

---

## 2. Datové anomálie a metodické poznámky

* **Extrémní výkyv v roce 2013 (Brambory):** Růst ceny konzumních brambor o 60,32 % byl podroben křížové kontrole. Nejedná se o chybu v datech, ale o reálnou historickou anomálii způsobenou extrémní neúrodou v ČR i v Evropě v kombinaci s nízkými zásobami z předchozího roku.
* **Pokles mezd v Peněžnictví (2013):** Meziroční pokles průměrné mzdy v sektoru *Peněžnictví a pojišťovnictví* o -8,91 % je způsoben plošným omezením ročních bonusů a restrukturalizací bankovního sektoru po dojezdu finanční krize, což kontrastuje s tehdejším růstem cen potravin.
* **Fixace cen u globálních komodit:** U banánů byla zjištěna extrémně nízká variance cen (průměrný nárůst 0,81 %). Data potvrzují status komodity jako marketingového "loss leaderu" obchodních řetězců.

---

## 3. Formát a dostupnost výstupů
Finální vyčištěná data jsou uložena v databázi ve dvou hlavních relačních tabulkách:
1.  `t_jmeno_prijmeni_project_SQL_primary_final` (obsahuje kompletně propojená a vyčištěná data mezd a cen potravin pro ČR bez NULL hodnot).
2.  `t_jmeno_prijmeni_project_SQL_secondary_final` (obsahuje makroekonomická data HDP, úrokových sazeb a kryptoměn/komodit pro širší kontext).

Obě tabulky jsou plně indexované, s vyčištěnými datovými typy (např. `DECIMAL` pro finanční částky namísto nepřesného `FLOAT`).
