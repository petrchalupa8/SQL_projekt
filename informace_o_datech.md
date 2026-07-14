# Informace o datech a technická dokumentace projektu

Tento dokument slouží jako technická dokumentace k projektu zaměřenému na analýzu vývoje mezd, cen potravin a makroekonomických ukazatelů v České republice. Popisuje použité zdrojové datové sady, způsob jejich zpracování, strukturu vytvořených tabulek a metodologii použitou při následné analytické části projektu.

---

# 1. Použité datové zdroje

Pro zpracování projektu byly využity veřejně dostupné datové sady z databáze společnosti Engeto, které vycházejí z oficiálních statistik Českého statistického úřadu (ČSÚ) a Světové banky.

Byly použity následující tabulky:

- **`czechia_payroll`** – obsahuje údaje o mzdách a počtech zaměstnanců v jednotlivých odvětvích české ekonomiky.
- **`czechia_payroll_industry_branch`** – číselník ekonomických odvětví (CZ-NACE), který umožňuje převod číselných kódů na názvy odvětví.
- **`czechia_payroll_calculation`** – obsahuje číselník způsobů výpočtu mezd.
- **`czechia_price`** – obsahuje historické ceny vybraných potravin sledovaných Českým statistickým úřadem.
- **`czechia_price_category`** – číselník kategorií potravin s názvy, jednotkami a množstvím.
- **`countries`** – seznam států včetně jejich geografického zařazení.
- **`economies`** – makroekonomické ukazatele jednotlivých států (HDP, populace a další ekonomické charakteristiky).

Na základě těchto tabulek byly vytvořeny dvě finální tabulky požadované zadáním projektu:

- `t_Petr_Chalupa_project_SQL_primary_final`
- `t_Petr_Chalupa_project_SQL_secondary_final`

Právě tyto dvě tabulky následně slouží jako jediný zdroj dat pro všechny analytické SQL dotazy.

---

# 2. Transformace a příprava dat

Před samotnou analýzou bylo nutné provést několik kroků vedoucích k očištění a sjednocení dat.

## Agregace cen potravin

Tabulka `czechia_price` obsahuje více záznamů v průběhu jednoho roku, protože ceny jsou sledovány v kratších časových intervalech.

Pro potřeby projektu bylo nutné převést tato data na společnou roční úroveň. Nejprve byl z časového údaje extrahován kalendářní rok a následně byla pro každou kategorii potraviny vypočtena průměrná cena za daný rok.

Díky této agregaci bylo možné ceny přímo porovnávat s ročními údaji o mzdách.

---

## Agregace mezd

Obdobným způsobem byla zpracována data o mzdách.

Původní tabulka obsahuje více typů ukazatelů, proto bylo nejprve potřeba vybrat pouze údaje představující průměrnou hrubou mzdu přepočtenou na plný pracovní úvazek.

Konkrétně byly ponechány pouze řádky s:

- **value_type_code = 5958** (průměrná hrubá mzda)
- **calculation_code = 200** (přepočtený počet zaměstnanců)

Tím byly odstraněny ostatní statistické ukazatele, které nebyly pro analýzu relevantní.

Následně byly mzdy zprůměrovány za jednotlivé roky a ekonomická odvětví.

---

## Propojení číselníkových tabulek

Původní datové sady obsahují řadu číselných identifikátorů.

Pro zvýšení čitelnosti byly všechny potřebné tabulky propojeny s odpovídajícími číselníky.

Konkrétně byly nahrazeny:

- kódy kategorií potravin jejich názvy,
- kódy ekonomických odvětví názvy odvětví.

Díky tomu již finální tabulky obsahují přímo textové hodnoty a není nutné dohledávat význam jednotlivých kódů.

---

## Vytvoření primární tabulky

Primární tabulka vznikla propojením agregovaných cen potravin a agregovaných mezd prostřednictvím společného kalendářního roku.

Výsledkem je jednotná datová sada obsahující:

- rok,
- ekonomické odvětví,
- průměrnou mzdu,
- kategorii potraviny,
- průměrnou cenu potraviny,
- množství,
- měrnou jednotku.

Protože ke spojení dochází pouze nad společnými roky obou datových sad, obsahuje výsledná tabulka pouze vzájemně srovnatelné období let **2006–2018**.

Právě tato tabulka představuje hlavní datový zdroj pro první čtyři analytické otázky projektu.

---

## Vytvoření sekundární tabulky

Sekundární tabulka byla vytvořena propojením tabulek `countries` a `economies`.

Tabulka `countries` byla využita především z důvodu geografické filtrace, protože umožňuje jednoznačně určit příslušnost jednotlivých států ke kontinentům.

Výsledná tabulka obsahuje pouze evropské státy a zahrnuje následující ukazatele:

- stát,
- rok,
- HDP,
- počet obyvatel,
- HDP na obyvatele.

Sekundární tabulka slouží jako zdroj makroekonomických dat využitých při analýze vztahu mezi vývojem HDP, mezd a cen potravin.

---

# 3. Datový slovník

## Primární tabulka

### `t_Petr_Chalupa_project_SQL_primary_final`

| Sloupec | Datový typ | Popis |
|----------|------------|-------|
| rok_mzda | INTEGER | Kalendářní rok sledování |
| odvetvi | VARCHAR | Název ekonomického odvětví |
| mzda | NUMERIC | Průměrná hrubá mzda v daném roce |
| potravina | VARCHAR | Název sledované potraviny |
| cena | NUMERIC | Průměrná cena potraviny za daný rok |
| rok_cena | FLOAT | Průměrná cena potraviny za daný rok |
| hodnota_mnozstvi | FLOAT | Velikost sledovaného balení |
| jednotka | VARCHAR | Jednotka množství (kg, l, ks apod.) |

---

## Sekundární tabulka

### `t_Petr_Chalupa_project_SQL_secondary_final`

| Sloupec | Datový typ | Popis |
|----------|------------|-------|
| stat | TEXT | Název státu |
| rok | INTEGER | Kalendářní rok |
| hdp | FLOAT | Hrubý domácí produkt |
| populace | FLOAT | Počet obyvatel |
| hdp_na_obyvatele | FLOAT | Přepočtený HDP na jednoho obyvatele |

---

# 4. Metodologie zpracování

Projekt byl zpracován výhradně pomocí jazyka SQL.

Při tvorbě finálních tabulek i analytických dotazů byly využity především **Common Table Expressions (CTE)**, které umožnily rozdělit složitější SQL dotazy do několika logických kroků. Díky tomu je celý kód přehlednější, lépe čitelný a jednotlivé části lze snadněji kontrolovat i upravovat.

Pro výpočty meziročních změn byly využity **analytické (window) funkce**, zejména funkce **LAG()** a **LEAD()**. Ty umožňují porovnávat aktuální hodnotu s hodnotou z předchozího nebo následujícího roku bez nutnosti vytvářet složité self-joiny. Tento přístup byl využit zejména při výpočtu meziročních změn mezd, cen potravin a HDP.

Dalším významným krokem bylo využití agregačních funkcí (`AVG`, `ROUND`) pro převod původních dat na roční průměry. Tím byla sjednocena časová granularita jednotlivých datových sad a umožněno jejich vzájemné porovnávání.

Veškeré analytické dotazy byly následně vytvářeny výhradně nad primární a sekundární tabulkou vytvořenou v první části projektu, čímž bylo splněno zadání projektu a zároveň zajištěna jednotná datová základna pro všechny výzkumné otázky.

---

# 5. Shrnutí

Výsledkem přípravy dat jsou dvě přehledné tabulky představující jednotnou datovou základnu celého projektu.

Primární tabulka spojuje informace o průměrných mzdách a cenách potravin v České republice a slouží jako hlavní zdroj pro analýzu kupní síly, vývoje mezd i cen potravin. Sekundární tabulka rozšiřuje projekt o makroekonomické ukazatele evropských států a umožňuje analyzovat souvislosti mezi vývojem HDP a sledovanými ekonomickými ukazateli.

Důraz byl kladen především na očištění dat, sjednocení časového rozlišení, čitelnost výsledných tabulek a využití moderních SQL technik, jako jsou Common Table Expressions a analytické (window) funkce.
