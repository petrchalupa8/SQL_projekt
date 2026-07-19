CREATE TABLE t_Petr_Chalupa_project_SQL_primary_final AS
-- Spojili jsme si kód kategorie a název potraviny + extrahovali jsme pouze rok.
WITH cte_spojeni_ceny_potraviny AS (
	SELECT 
		cp.value AS cena_parcialni,
		DATE_PART ('year', cp.date_from) AS rok_cena,
		cpc.name AS potravina,
		cpc.price_value AS hodnota_mnozstvi,
		cpc.price_unit AS jednotka
	FROM czechia_price cp
	JOIN czechia_price_category cpc
		ON cpc.code = cp.category_code
),
-- Zprůměrovali jsme cenu za rok dané potraviny.
cte_prumer_cena_rok AS (
	SELECT 
		ROUND(AVG(cena_parcialni)::numeric, 2) AS cena,
		rok_cena,
		potravina,
		hodnota_mnozstvi,
		jednotka
	FROM cte_spojeni_ceny_potraviny
	GROUP BY rok_cena, potravina, hodnota_mnozstvi, jednotka
),
-- Napojili jsme název odvětví a filtrovali mzdy dle kódu a přepočtené hodnoty - eliminovali hodnoty fyzické.
cte_napojeni_nazev_mzdy AS (
	SELECT *
	FROM czechia_payroll cp 
	JOIN czechia_payroll_industry_branch cpib
		ON cp.industry_branch_code = cpib.code
	WHERE cp.value_type_code = 5958
		AND cp.calculation_code = 200
),
-- Zprůměrovali jsme mzdu v rámci oboru za každý rok.
cte_prumer_mzda AS (
	SELECT 
		ROUND(AVG(value)::numeric, 2) AS mzda,
		payroll_year AS rok_mzda,
		name AS odvetvi
	FROM cte_napojeni_nazev_mzdy
	GROUP BY rok_mzda, name
)
SELECT *
FROM cte_prumer_mzda cpm
JOIN cte_prumer_cena_rok cpcr
	ON cpcr.rok_cena = cpm.rok_mzda
ORDER BY odvetvi, rok_mzda, potravina;

CREATE TABLE t_Petr_Chalupa_project_SQL_secondary_final AS
SELECT 
	c.country AS stat,
	e."year" AS rok,
	e.gdp AS hdp,
	e.population AS populace,
	(e.gdp / e.population) AS hdp_na_obyvatele
FROM countries c 
JOIN economies e
	ON e.country = c.country 
WHERE c.continent = 'Europe'
ORDER BY stat, rok;


-- Otázka č.1 Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
WITH cte_seskupeni_mzdy AS (
	SELECT
		mzda,
		rok_mzda,
		odvetvi
	FROM t_Petr_Chalupa_project_SQL_primary_final
	GROUP BY odvetvi, mzda, rok_mzda
),
cte_LAG_mzda AS (
	SELECT 
		mzda,
		rok_mzda,
		odvetvi,
		LAG(mzda) OVER (PARTITION BY odvetvi ORDER BY rok_mzda) AS mzda_minuly_rok
	FROM cte_seskupeni_mzdy
),
cte_not_null AS (
	SELECT *
	FROM cte_LAG_mzda
	WHERE mzda_minuly_rok IS NOT NULL
	ORDER BY odvetvi, rok_mzda
),
cte_mezirocni_porovnani_mzdy AS (
	SELECT 
		*,
		CASE 
			WHEN mzda < mzda_minuly_rok THEN 'mzda klesá'
			ELSE 'mzda neklesá'
		END mezirocni_porovnani_mzdy
	FROM cte_not_null
)
SELECT 
	odvetvi,
	count(odvetvi) AS pocet_let_s_klesajici_mzdou_v_odvetvi
FROM cte_mezirocni_porovnani_mzdy
WHERE mezirocni_porovnani_mzdy = 'mzda klesá'
GROUP BY odvetvi;

-- Otázka č.2 Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

-- Vypočítali jsme si průměrnou mzdu za rok napříč odvětvími.
WITH cte_prumerna_mzda AS (
	SELECT 
		ROUND(AVG(mzda), 2) AS prumerna_mzda_rok,
		rok_mzda
	FROM t_Petr_Chalupa_project_SQL_primary_final
	GROUP BY rok_mzda
	ORDER BY rok_mzda
),
-- Vypočítali jsme si cenu potraviny za rok napříč odvětvími.
cte_prumerna_cena AS (
	SELECT 
		ROUND(AVG(cena)::numeric, 2) AS prumerna_cena_rok,
		rok_cena,
		potravina,
		hodnota_mnozstvi,
		jednotka
	FROM t_Petr_Chalupa_project_SQL_primary_final
	GROUP BY rok_cena, potravina, hodnota_mnozstvi, jednotka
	ORDER BY rok_cena, potravina
),
-- Spojili jsme si průměrnou mzdu napříč obory za kalendářní rok s cenami jednotlivých potraviny za daný kalendářní rok.
cte_spojeni_cena_mzda AS (
	SELECT *
	FROM cte_prumerna_cena cpc
	JOIN cte_prumerna_mzda cpm
		ON cpc.rok_cena = cpm.rok_mzda
)
-- Spočítali jsme, kolik celých kilogramů/litrů potraviny jsme schopni zakoupit za průměrnou mzdu.(lze koupit jen celé balení, tedy cokoliv v desetiné čárce nelze zakoupit)
SELECT 
	rok_mzda,
	potravina,
	FLOOR(prumerna_mzda_rok / prumerna_cena_rok) AS kg_l_mzda,
	jednotka
FROM cte_spojeni_cena_mzda
WHERE potravina IN ('Chléb konzumní kmínový', 'Mléko polotučné pasterované');

-- Otázka č.3 Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)? 
-- Odpověď A - bereme potravinu, která měl a nejpomalejší zdražování a počítá se zde také zlevňování.

WITH cte_odebrani_odvetvi AS (
	SELECT
		rok_cena AS rok,
		AVG(cena) AS cena,
		potravina
	FROM t_Petr_Chalupa_project_SQL_primary_final
	GROUP BY potravina, rok
),
cte_lag AS (
	SELECT
		*,
		LAG(cena) OVER (PARTITION BY potravina ORDER BY rok) AS cena_minuly_rok
	FROM cte_odebrani_odvetvi
),
cte_mezirocni_narust AS (
	SELECT
		*,
		(cena / cena_minuly_rok) AS mezirocni_narust
	FROM cte_lag
	WHERE cena_minuly_rok IS NOT NULL
),
cte_prumerny_narust_potravina AS (
	SELECT 
		potravina,
		AVG(mezirocni_narust) AS prumerny_narust
	FROM cte_mezirocni_narust
	GROUP BY potravina
)
SELECT *
FROM cte_prumerny_narust_potravina
ORDER BY prumerny_narust
LIMIT 1;

-- Odpověď B - bereme jen explicitně potraviny, které zdražovaly (nezlevňovaly).

WITH cte_odebrani_odvetvi AS (
	SELECT
		rok_cena AS rok,
		AVG(cena) AS cena,
		potravina
	FROM t_Petr_Chalupa_project_SQL_primary_final
	GROUP BY potravina, rok
),
cte_lag AS (
	SELECT
		*,
		LAG(cena) OVER (PARTITION BY potravina ORDER BY rok) AS cena_minuly_rok
	FROM cte_odebrani_odvetvi
),
cte_mezirocni_narust AS (
	SELECT
		*,
		(cena / cena_minuly_rok) AS mezirocni_narust
	FROM cte_lag
	WHERE cena_minuly_rok IS NOT NULL
),
cte_prumerny_narust_potravina AS (
	SELECT 
		potravina,
		AVG(mezirocni_narust) AS prumerny_narust
	FROM cte_mezirocni_narust
	GROUP BY potravina
)
SELECT *
FROM cte_prumerny_narust_potravina
WHERE prumerny_narust > 1
ORDER BY prumerny_narust
LIMIT 1;

-- Otázka č.4 Ptáme se "Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?", neptáme se na cenové šoky. Zde je ideální porovnat meziroční nárůsty mezd (za všechny obory) a nárůsty cen (za všechny kategorie).
WITH cte_prumer_mzda_cena AS (	
	SELECT 
		rok_mzda AS rok,
		ROUND(AVG(cena), 2) AS rocni_prumer_cena,
		ROUND(AVG(mzda), 2) AS rocni_prumer_mzda
	FROM t_Petr_Chalupa_project_SQL_primary_final
	GROUP BY rok_mzda
),
cte_lag AS (
	SELECT
		rok,
		rocni_prumer_cena,
		LAG(rocni_prumer_cena) OVER (ORDER BY rok) AS cena_minuly_rok,
		rocni_prumer_mzda,
		LAG(rocni_prumer_mzda) OVER (ORDER BY rok) AS mzda_minuly_rok
	FROM cte_prumer_mzda_cena
),
cte_mezirocni_narust AS (
	SELECT 
		rok,
		rocni_prumer_cena,
		cena_minuly_rok,
		(rocni_prumer_cena / cena_minuly_rok) AS mezirocni_narust_cena,
		rocni_prumer_mzda,
		mzda_minuly_rok,
		(rocni_prumer_mzda / mzda_minuly_rok) AS mezirocni_narust_mzda
	FROM cte_lag
),
cte_provnani_narustu_ceny_mzdy AS (
	SELECT 
		*,
		(mezirocni_narust_cena / mezirocni_narust_mzda) AS porovnani_narustu_cena_mzda
	FROM cte_mezirocni_narust
),
cte_inflace AS (
	SELECT 
		*,
		CASE
			WHEN porovnani_narustu_cena_mzda < 1 THEN 'mzdy rostly rychleji než ceny'
			WHEN porovnani_narustu_cena_mzda = 1 THEN 'mzdy rostly stejně rychle jako ceny'
			WHEN porovnani_narustu_cena_mzda > 1.1 THEN 'ceny rostly výrazně rychleji než mzdy'
			ELSE 'ceny rostly rychleji než mzdy'
		END stav_inflace
	FROM cte_provnani_narustu_ceny_mzdy
	WHERE cena_minuly_rok IS NOT NULL
	ORDER BY rok
)
SELECT *
FROM cte_inflace;
WHERE stav_inflace = 'ceny rostly výrazně rychleji než mzdy';
	

-- Otázka č.5 Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, 
-- projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

WITH cte_prumer_mzda_cena AS (	
	SELECT 
		rok_mzda AS rok,
		ROUND(AVG(cena), 2) AS rocni_prumer_cena,
		ROUND(AVG(mzda), 2) AS rocni_prumer_mzda
	FROM t_Petr_Chalupa_project_SQL_primary_final
	GROUP BY rok_mzda
),
cte_lag AS (
	SELECT
		rok,
		rocni_prumer_cena,
		LAG(rocni_prumer_cena) OVER (ORDER BY rok) AS cena_minuly_rok,
		rocni_prumer_mzda,
		LAG(rocni_prumer_mzda) OVER (ORDER BY rok) AS mzda_minuly_rok
	FROM cte_prumer_mzda_cena
),
cte_mezirocni_narust AS (
	SELECT 
		rok,
		rocni_prumer_cena,
		cena_minuly_rok,
		(rocni_prumer_cena / cena_minuly_rok) AS mezirocni_narust_cena,
		rocni_prumer_mzda,
		mzda_minuly_rok,
		(rocni_prumer_mzda / mzda_minuly_rok) AS mezirocni_narust_mzda
	FROM cte_lag
),
cte_hdp_cz AS (
	SELECT 
		stat,	
		rok,	
		hdp,
		LEAD(hdp) OVER (ORDER BY rok) AS hdp_dalsi_rok,
		populace,	
		hdp_na_obyvatele
	FROM t_petr_chalupa_project_sql_secondary_final tpcpssf
	WHERE hdp IS NOT NULL
		AND stat = 'Czech Republic'
),
cte_rust_hdp AS (
	SELECT 
		stat,	
		rok,	
		hdp,
		hdp_dalsi_rok,
		(hdp_dalsi_rok / hdp) AS narust_hdp_dalsi_rok,
		populace,	
		hdp_na_obyvatele
	FROM cte_hdp_cz
),
cte_spojeni_hdp_cen_mezd AS (
	SELECT 
		crh.rok,
		crh.narust_hdp_dalsi_rok,
		cmn.mezirocni_narust_cena,
		cmn.mezirocni_narust_mzda
	FROM cte_rust_hdp crh
	JOIN cte_mezirocni_narust cmn
		ON crh.rok = cmn.rok
)
SELECT *
FROM cte_spojeni_hdp_cen_mezd
WHERE mezirocni_narust_cena IS NOT NULL
ORDER BY rok;


-- Původní verze SQL kódu. Chybné - nebrat v úvahu.


-- 1.Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

CREATE VIEW serazeno_mzdy AS
SELECT 
	cp.payroll_year AS rok,
	ROUND(AVG(cp.value),0) AS prumerna_mzda,
	cpib.name AS obor
FROM czechia_payroll cp 
JOIN czechia_payroll_industry_branch cpib 
	ON cp.industry_branch_code = cpib.code
JOIN czechia_payroll_value_type cpvt 
	ON cp.value_type_code = cpvt.code
WHERE cpvt.name = 'Průměrná hrubá mzda na zaměstnance'
GROUP BY cp.payroll_year, cpib.name
ORDER BY obor, rok ASC;


WITH rocni_mzdy AS (
    SELECT *
    FROM serazeno_mzdy 
),
srovnani_s_minulym_rokem AS (
    SELECT 
        rok,
        obor,
        prumerna_mzda,
        LAG(prumerna_mzda) OVER (PARTITION BY obor ORDER BY rok) AS mzda_minuly_rok
    FROM rocni_mzdy
)
SELECT 
    rok,
    obor,
    prumerna_mzda,
    mzda_minuly_rok,
    (prumerna_mzda - mzda_minuly_rok) AS mezirocni_rozdil
FROM srovnani_s_minulym_rokem
WHERE prumerna_mzda < mzda_minuly_rok
ORDER BY mezirocni_rozdil ASC, rok DESC

--VIEW pro filtraci roků 2006 a 2018 ( pro úkol 2)
CREATE VIEW vw_obor_rok AS
SELECT 
	rok,
	prumerna_mzda,
	obor
FROM serazeno_mzdy
WHERE rok IN (2006, 2018)
ORDER BY rok, obor;

SELECT *
FROM vw_obor_rok;

-- 2.Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období 
-- v dostupných datech cen a mezd?

-- Napojili jsme taulku cp a cpc a vytvořili si datum

CREATE VIEW vw_ceny AS
SELECT 
	cp.value::numeric AS cena,
	DATE_PART('year',cp.date_from)::int AS rok_od,
	cpc.name AS kategorie,
	cpc.price_value AS hodnota_jednotka,
	cpc.price_unit AS jednotka
FROM czechia_price cp 
JOIN czechia_price_category cpc 
	ON cp.category_code = cpc.code;

SELECT *
FROM vw_ceny;

-- Ověření, že roky od a do jsou vždy stejné a lze porovnávat s roky ze mzdy.
SELECT *
FROM vw_ceny
WHERE rok_od != rok_do;

-- Zjištění prvního a posledního období
-- 1.období je 2006 a poslední je 2018

SELECT *
FROM vw_ceny
ORDER BY rok_od;

SELECT *
FROM vw_ceny
ORDER BY rok_od DESC;

-- Vytvoření průměrné ceny a seskupení do roků a sortimentu - filtrace roků 2006 a 2018

CREATE VIEW vw_prumerna_cena AS
SELECT
	ROUND(AVG(cena),2) AS prumerna_cena,
	rok_od,
	kategorie,
	hodnota_jednotka,
	jednotka
FROM vw_ceny
GROUP BY rok_od, kategorie, hodnota_jednotka, jednotka
HAVING rok_od IN (2006,2018)
ORDER BY  rok_od, kategorie, prumerna_cena DESC;

SELECT *
FROM vw_prumerna_cena;

-- Zefektivnění pomocí cte

WITH cte_prumerna_cena AS (
-- průměrná mzda a sjednocení zboží
	SELECT
		ROUND(AVG(cena),2) AS prumerna_cena,
		rok_od,
		kategorie,
		hodnota_jednotka, 
		jednotka
	FROM vw_ceny
	GROUP BY rok_od, kategorie, hodnota_jednotka, jednotka
	HAVING rok_od IN (2006,2018)
	ORDER BY  rok_od, kategorie, prumerna_cena DESC
),
-- filtrace chleba a mléka
cte_chleb_mleko AS (
SELECT *
FROM cte_prumerna_cena
WHERE kategorie ILIKE '%Chléb%' OR kategorie ILIKE '%mléko%'
),
-- Napojení mzdy a ceny na bázi cizího klíče dle roku
cte_pocet_ks AS (
SELECT 
	chm.prumerna_cena,
	chm.rok_od,
	chm.kategorie,
	chm.hodnota_jednotka,
	chm.jednotka,
	vor.prumerna_mzda,
	vor.obor
FROM cte_chleb_mleko AS chm
JOIN vw_obor_rok AS vor
	ON chm.rok_od = vor.rok
ORDER BY rok_od, obor
)
-- Výpočet, kolik litrů mléka a kilogramů chlába by bylo možné si pořídit dle průměrných 
-- mezd v jednotlivých oborech a definovaných letech se zaokrouhlením dolů - 
-- kupují se celé suroviny.
SELECT
	rok_od,
	kategorie,
	prumerna_mzda,
	obor,
	FLOOR(prumerna_mzda / prumerna_cena) AS kg_l_mzda,
	jednotka
FROM cte_pocet_ks
ORDER BY obor, rok_od;

-- 3.Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)? 
SELECT *
FROM vw_prumerna_cena vpc
ORDER BY kategorie, rok_od;

-- Vytvoření meziročního nárůstu dle CTE. 

WITH cte_prehled_ceny AS (
	SELECT
		ROUND(AVG(cena),2) AS prumerna_cena,
		rok_od,
		kategorie
	FROM vw_ceny
	GROUP BY rok_od, kategorie
	ORDER BY  kategorie, rok_od
),
cte_funkce_lag AS (
	SELECT 
		prumerna_cena,
		rok_od,
		LAG(prumerna_cena) OVER (PARTITION BY kategorie ORDER BY rok_od) AS cena_predchozi_rok,
		kategorie
	FROM cte_prehled_ceny
),
cte_prumerny_narust AS (
	SELECT 
		kategorie,
		ROUND(AVG((((prumerna_cena - cena_predchozi_rok) / cena_predchozi_rok)*100)), 2) AS mezirocni_srovnani
	FROM cte_funkce_Lag
	WHERE cena_predchozi_rok IS NOT NULL
	GROUP BY kategorie
)
SELECT *
FROM cte_prumerny_narust
WHERE mezirocni_srovnani > 0
ORDER BY mezirocni_srovnani
LIMIT 1;
	
-- 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

-- Nárust průmerné mzdy meziročně napříč obory.

CREATE VIEW vw_mezirocni_rust_mzdy AS
WITH cte_narust_mezd AS (
	SELECT 
		rok,
		prumerna_mzda,
		LAG(prumerna_mzda) OVER (PARTITION BY obor ORDER BY rok) AS lonska_mzda,
		obor
	FROM serazeno_mzdy sm
),
cte_bez_null AS (
	SELECT *
	FROM cte_narust_mezd
	WHERE lonska_mzda IS NOT NULL
)
SELECT 
	rok,
	obor,
	prumerna_mzda,
	lonska_mzda,
	ROUND((((prumerna_mzda - lonska_mzda) / lonska_mzda) * 100), 2) AS mezirocni_narust_mzdy
FROM cte_bez_null;

SELECT *
FROM vw_mezirocni_rust_mzdy;

-- Nárust průmerné ceny meziročně napříč potravinami.

CREATE VIEW vw_mezirocni_rust_ceny AS
WITH cte_prumerna_cena AS (
SELECT 
	rok_od,
	ROUND(AVG(cena), 2) AS prumerna_cena,
	kategorie
FROM vw_ceny
GROUP BY rok_od, kategorie
ORDER BY kategorie, rok_od
),
cte_lonska_cena AS (
SELECT 
	rok_od,
	prumerna_cena,
	LAG(prumerna_cena) OVER (PARTITION BY kategorie ORDER BY rok_od) AS lonska_cena,
	kategorie
FROM cte_prumerna_cena
)
SELECT
	rok_od,
	prumerna_cena,
	lonska_cena,
	ROUND((((prumerna_cena - lonska_cena) / lonska_cena) * 100), 2) AS mezirocni_narust_ceny,
	kategorie
FROM cte_lonska_cena
WHERE lonska_cena IS NOT NULL
ORDER BY kategorie, rok_od;

SELECT *
FROM vw_mezirocni_rust_ceny
ORDER BY kategorie, rok_od;

-- Spojeni meziročního nárústu mzdy a ceny.

CREATE VIEW vw_spojeni_ceny_mzdy AS
SELECT 
	*,
	(mezirocni_narust_ceny - mezirocni_narust_mzdy) AS inflace
FROM vw_mezirocni_rust_mzdy vmrm
JOIN vw_mezirocni_rust_ceny vmrc
	ON vmrm.rok = vmrc.rok_od;

-- filtrace meziroční nárůstu cen potravin výrazně vyšší než růst mezd (větší než 10 %)
CREATE VIEW vw_inflace_mzda_cena AS
WITH cte_porovnani_rustu AS (
	SELECT
		*,
		CASE 
			WHEN inflace > 10 THEN 'vyšší růst cen o 10% a více'
			ELSE 'nižší růst cen než o 10%'
		END porovnani_rustu
	FROM vw_spojeni_ceny_mzdy
)
SELECT *
FROM cte_porovnani_rustu
WHERE porovnani_rustu = 'vyšší růst cen o 10% a více';

SELECT *
FROM vw_inflace_mzda_cena
ORDER BY porovnani_rustu;

-- 5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, 
-- projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

WITH cte_econimies_cz AS (
	SELECT *
	FROM economies eco
	WHERE country = 'Czech Republic'
),
cte_spojeni_hdp_cena_mzda AS (
	SELECT 
		ecz."year" AS rok,
		ecz.gdp AS hdp,
		ROUND(AVG(scm.prumerna_mzda), 2) AS prumerna_mzda_rok,
		ROUND(AVG(scm.mezirocni_narust_mzdy), 2) AS mezirocni_narust_mzdy_rok,
		ROUND(AVG(scm.prumerna_cena), 2) AS prumerna_cena_rok,
		ROUND(AVG(scm.mezirocni_narust_ceny), 2) AS mezirocni_narust_ceny_rok
	FROM cte_econimies_cz ecz
	JOIN vw_spojeni_ceny_mzdy scm
		ON scm.rok = ecz."year"
	GROUP BY ecz."year", ecz.gdp
	ORDER BY rok
),
cte_lead_hdp AS (
SELECT 
	*, 
	LEAD(hdp) OVER (ORDER BY rok) AS hdp_dalsi_rok
FROM cte_spojeni_hdp_cena_mzda
)
SELECT
	*,
	ROUND((((hdp_dalsi_rok - hdp) / hdp) * 100)::numeric, 2) AS mezirocni_rust_hdp
FROM cte_lead_hdp
WHERE hdp_dalsi_rok IS NOT NULL;

-- 1. tabulka

CREATE VIEW vw_mzdy_vsechny_roky AS
WITH rocni_mzdy AS (
    SELECT *
    FROM serazeno_mzdy 
),
srovnani_s_minulym_rokem AS (
    SELECT 
        rok,
        obor,
        prumerna_mzda,
        LAG(prumerna_mzda) OVER (PARTITION BY obor ORDER BY rok) AS mzda_minuly_rok
    FROM rocni_mzdy
)
SELECT 
    rok,
    obor,
    prumerna_mzda,
    mzda_minuly_rok,
    (prumerna_mzda - mzda_minuly_rok) AS mezirocni_rozdil
FROM srovnani_s_minulym_rokem;

CREATE TABLE t_petr_chalupa_project_sql_primary_final AS
WITH cte_ceny_rok_prumer AS (
	SELECT 
		rok_od,
		ROUND(avg(cena), 2) AS prumerna_cena_rok,
		kategorie
	FROM vw_ceny
	GROUP BY rok_od, kategorie
	ORDER BY rok_od
)
SELECT *
FROM cte_ceny_rok_prumer crp 
JOIN vw_mzdy_vsechny_roky vmvr
	ON crp.rok_od = vmvr.rok;

-- 2. tabulka
CREATE TABLE t_Petr_Chalupa_project_SQL_secondary_final AS
WITH cte_staty_evropa AS (
	SELECT 
		co.country,       
        co.continent,     
        eco."year",   
        eco.gdp,
        eco.gini,
        eco.population
	FROM economies eco 
	JOIN countries co 
		ON co.country = eco.country
),
cte_lag_gdp AS (
	SELECT 
		country,
		LAG(gdp) OVER (PARTITION BY country ORDER BY "year") AS gdp_minuly_rok,
		"year",
		gdp,
		gini,
		population,
		continent
	FROM cte_staty_evropa
)
SELECT
	country,
	"year",
	gdp,
	(((gdp - gdp_minuly_rok) / gdp_minuly_rok) * 100) AS gdp_procentualni_zmena,
	gini,
	population
FROM cte_lag_gdp
WHERE continent = 'Europe'
	AND gdp IS NOT NULL;

