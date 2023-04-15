select *
from salesdatasample


/*MIS EN FORME COLONNE COUNTRY */
 update salesdatasample
SET COUNTRY = UPPER(COUNTRY)

/*VERIFICATION DE DOUBLONS (AUCUN DOUBLON) */
select *
from (
select *,
ROW_NUMBER() OVER (PARTITION BY ORDERNUMBER,QUANTITYORDERED,SALES,STATUS,PRODUCTCODE order by ORDERNUMBER) as doublons
from salesdatasample)verificationdoublons
WHERE	doublons > 1

/*VENTE PAR PRODUITS */

select PRODUCTLINE, SUM(SALES) as VENTESPDTS
FROM salesdatasample
GROUP BY PRODUCTLINE
order by 2 desc

/* VENTES PAR PAYS */

select COUNTRY, SUM(SALES) as VENTESPAYS
FROM salesdatasample
GROUP BY COUNTRY
order by 2 desc


/* VENTES PAR VILLE DU MEILLEUR PAYS*/

Select*
from
(
select COUNTRY, CITY, SUM(SALES) as VENTEPARVILLE
FROM salesdatasample
GROUP BY COUNTRY, CITY)Vtepays
WHERE COUNTRY = 'USA'
ORDER BY 3 desc


/*VENTES PAR DEALSIZE */
select DEALSIZE, SUM(SALES) as VENTESPARTAILLE
FROM salesdatasample
GROUP BY DEALSIZE


/* VENTE TOTAL PAR ANNEE*/
select YEAR_ID, SUM(SALES) as VENTESPARANNEE
FROM salesdatasample
GROUP BY YEAR_ID
order by 1 asc

/*MEILLEUR PDT DU MOIS (MEILLEUR MOIS 2004 SPECIALEMENT)*/
WITH CTE_MOIS AS
(
	--Meilleur mois : 11 => Novembre
	select PRODUCTLINE, MONTH_ID, SUM(SALES) as VentesPdtMois
	from salesdatasample
	WHERE YEAR_ID = 2004
	GROUP BY PRODUCTLINE, MONTH_ID
)

	select *
	from CTE_MOIS
	WHERE MONTH_ID = 11



/*RFM ANALYSE (CLASSEMENT DES CLIENTS) */

--CLASSEMENT GROUPER PAR R_F_M
DROP TABLE IF EXISTS #ClassementRFM
Select CUSTOMERNAME, Recurrence, Frequence, Monetaire,
		NTILE(4) OVER (ORDER BY Recurrence )R,
		NTILE(4) OVER (ORDER BY Frequence DESC)F,
		NTILE(4) OVER (ORDER BY Monetaire DESC)M
into #ClassementRFM
from 
(
--RECURRENCE = NOMBRE TOTAL DE JOUR DE CHAQUE CLIENT DEPUIS LE DERNIER ACHAT
Select *, DATEDIFF(DD,DernDateAchatClt,DernDateAchat) Recurrence
from
(
--FREQUENCE = NOMBRE TOTAL D'ACHAT PASSE PAR CLIENT
--MONETAIRE = VALEUR MOYENNE D'ACHAT DE CHAQUE CLIENT
Select DISTINCT(CUSTOMERNAME),
				MAX(ORDERDATE)DernDateAchatClt, 
				COUNT(ORDERNUMBER)Frequence,
				AVG(SALES)Monetaire,
				(select MAX(ORDERDATE) from salesdatasample)DernDateAchat
from salesdatasample
GROUP BY CUSTOMERNAME)FreqetMon
					 )Recurrence

/*CLASSIFICATION DES CLIENT PAR RFM*/
Select *, 
		CASE
			WHEN RFM in (444,443,434,433,432,423,344,343,441,414) THEN 'Clients Perdus'
			WHEN RFM in (422,421,412,311,341) THEN 'Clients à Risque'
			WHEN RFM in (244,144,224) THEN 'Nouveaux Clients'
			WHEN RFM in (333,332,322,233) THEN 'Clients Potentiellement Perdus'
			WHEN RFM in (232,222,234,133,223,123,221,212,211) THEN 'Clients Actifs'
			WHEN RFM in (122,121,112,111) THEN 'Clients Loyals'
			ELSE 'Client à Classifier'
		END as CLASSEMENT_CLIENTS 
from
(
	select CUSTOMERNAME, CAST(R as varchar)+CAST(F as varchar)+CAST(M as varchar)RFM 
	from #ClassementRFM
	)RECURFREQUENMONET
ORDER BY CLASSEMENT_CLIENTS 


