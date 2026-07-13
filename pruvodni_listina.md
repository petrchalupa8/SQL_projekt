# Průvodní listina a popis mezivýsledků projektu

Tento dokument slouží jako průvodní zpráva k výzkumnému projektu zaměřenému na analýzu mezd, cen potravin a HDP v České republice. Popisuje postup zpracování, strukturu mezivýsledků a logické vazby mezi datovými sadami.

---

Cílem projektu bylo ověřit sadu 5 výzkumných hypotéz týkajících se ekonomické situace obyvatel ČR v letech 2006–2018. 
Zdrojem dat byly primární sady Českého statistického úřadu (ČSÚ) pro mzdy a ceny potravin a makroekonomická data Světové banky / ČSÚ pro HDP.

### Postup zpracování:
1. **Vytvořili jsme dvě tabulky dle zadání:** Vytvořili jsme výchozí tabulky, ze kterých jsme dále čerpali a využívali je v dalších částech projektu.
2. **Vytvořili jsme 5 Common table expression SQL, které umožní vyčíst odpovědi na zadané otázky.** 

---

* **Hypotéza 1 (Růst mezd):** Potvrdilo se, že růst mezd byl výrazným jevem a byl trendem pro větinu let. Celkově u 16 odvětví z celkových 19 se ale meziroční pokles vyskytnul. Jako nejrizikovější obor se jeví Těžba a dobývání, kde došlo celkem čtyřikrát k meziročnímu poklesu mezd.
*  **Hypotéza 2 (Kupní síla):** Zde jsme upustili od segmentování mezd dle oborů a zaměřili jsme se na jednu průměrnou mzdu napříč všemi obory za každý jeden z měřených roků. Následně jsme si zanalyzovali a zprůměrovali ceny zkoumaných potravin (Mléko polotučné pasterované, Chléb konzumní kmínový) pro každý rok. Ze zjištených hodnot bylo pomocí jednoduchého podílu zjištěno, kolik kg/l sortimentu si lze za průměrnou mzdu pořídit. Nebrali jsme v úvahu hodnoty za desetinou čárkou, jelikož si obvykle nelze koupit pouze část celku. Zajímavý výsledek byl, že průměrná mzda uožňuje nákupu sortimentu přesahující ve všech případech jednu tunu.
*  **Hypotéza 3 (Stabilita cen):** Našim úkolem bylo zanalyzovat zdražování jednotlivých kategorií potravin a vypsat kategorii, která zdražuje nejpomaleji. Odpověď A: Brali jsme v úvahu také negativní zdražování (zlevňování). V tomto případě byl výsledkem Cukr krystal. Odpověď B: Brali jsme v úvahu pouze zdražování. Zde jako nejpomaleji rostoucí cena vzešly Banány žluté.
*  **Hypotéza 4 (Inflace):** Naším úkol bylo ověřit, zda existuje rok, kdy byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %). Po analýze se ukázalo, že meziroční nárusty byly oběma směry. V některých letech došlo k rychlejšímu růstu cena v některém k rychlejšímu růstu mezd. V žádném však nedošlo k meziročním růstu nad 10 %.
*  **Hypotéza 5 (Vliv HDP):** Z výsledných dat se nepotrvrdilo, že by HDP mělo vliv na růst cena mezd, což dokazuje rok 2017, kdy byl pokles celkového HDP, avšak růst cen byl téměř o 10% vyšší.
