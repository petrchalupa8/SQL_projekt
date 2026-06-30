# Průvodní listina a popis mezivýsledků projektu

Tento dokument slouží jako průvodní zpráva k výzkumnému projektu zaměřenému na analýzu mezd, cen potravin a HDP v České republice. Popisuje postup zpracování, strukturu mezivýsledků a logické vazby mezi datovými sadami.

---

## 1. Cíl projektu a metodika
Cílem projektu bylo ověřit sadu 5 výzkumných hypotéz týkajících se ekonomické situace obyvatel ČR v letech 2006–2018. 
Zdrojem dat byly primární sady Českého statistického úřadu (ČSÚ) pro mzdy a ceny potravin a makroekonomická data Světové banky / ČSÚ pro HDP.

### Postup zpracování:
1. **Čištění a filtrace dat:** Odstranění nekompletních záznamů a agregace mezd na roční průměry za jednotlivá odvětví.
2. **Sjednocení časových řad:** Harmonizace období na srovnatelné roky (2006–2018).
3. **Výpočet odvozených metrik:** Výpočet reálné kupní síly (kolik kg/l komodity lze koupit za průměrný plat) a meziročních procentuálních změn.
4. **Makroekonomická korelace:** Propojení vývoje cen a mezd s dynamikou HDP s uvážením časového posunu (setrvačnosti).

---

## 2. Struktura mezivýsledků (Mezitabulky)
V průběhu analýzy byly v databázi vytvořeny klíčové mezivýsledky, které sloužily jako podklad pro finální syntézu:

### A. Agregované mzdy podle odvětví
* **Popis:** Obsahuje očištěné průměrné roční mzdy rozdělené podle klasifikace odvětví CZ-NACE.
* **Klíčové metriky:** Rok, kód odvětví, název odvětví, průměrná mzda v Kč.

### B. Průměrné roční ceny potravin
* **Popis:** Agregované měsíční reprezentanty cen vybraných potravinových komodit na roční průměry.
* **Klíčové metriky:** Rok, kód potraviny, název potraviny, průměrná cena v Kč za jednotku (kg/l).

### C. Komparativní matice kupní síly
* **Popis:** Spojená tabulka (JOIN) pro výzkumnou otázku č. 2, která přepočítává průměrnou mzdu každého odvětví na reálný objem chleba a mléka.

---

## 3. Shrnutí naplnění hypotéz
* **Hypotéza 1 (Růst mezd):** Potvrzena. Všechna odvětví zaznamenala mezi lety 2006 a 2018 růst, žádné dlouhodobě neklesalo.
* **Hypotéza 2 (Kupní síla):** Potvrzena. Kupní síla obyvatel se plošně zvýšila, u mléka výrazněji než u chleba.
* **Hypotéza 3 (Stabilita cen):** Identifikována nejstabilnější komodita – Banány žluté s průměrným meziročním růstem pouze 0,81 %.
* **Hypotéza 4 (Cenové šoky):** Potvrzena existence extrémních let (zejména rok 2013 u brambor s nárůstem přes 60 %).
* **Hypotéza 5 (Vliv HDP):** Potvrzen vliv HDP na mzdy a ceny s ročním zpožděním (ekonomická setrvačnost).
