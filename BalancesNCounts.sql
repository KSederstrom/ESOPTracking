/*Balances and Account Count
For each month, find out the market value and share count for each fund in the ESOP plan. 
Also find out how many people are there in each fund.
Make a distinction between the Cash, B stock, and normal (original) stock.
*/
SELECT 
	Plan_number
    ,Calendar_day
	,CASE
		WHEN FUND LIKE 'SA2A%' THEN 'UHAL'
		WHEN FUND IN ('SA2F-AMERCO SERIES N STCK') THEN 'UHAL.B'
		WHEN FUND IN ('0458-FID GOVT MMKT') THEN 'MMKT'
		ELSE 'Unknown' END AS Fund_IDs
	,COUNT(SSN) AS TM_Counts
	,SUM(Market_value) AS MKTValue_Total
	,SUM(Share_balance) AS ShareTotal
	,CASE WHEN SSN = '999-99-9999F' THEN 'Forfeiture'
		WHEN SSN = '999-99-9999S' THEN 'Suspense'
		ELSE 'Participant' END AS Account
FROM [DevRaw].[dbo].[Fund_Balances_n_CostBasis_EOM]
WHERE Plan_number = '75952'
GROUP BY 
	Plan_number
    ,Calendar_day
    ,Fund
	,CASE WHEN SSN = '999-99-9999F' THEN 'Forfeiture'
		WHEN SSN = '999-99-9999S' THEN 'Suspense'
		ELSE 'Participant' END 
ORDER BY Calendar_day DESC, Fund DESC