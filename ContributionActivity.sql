/* Contribution Activity - Monthly contribution activityt by fund for ESOP
Find how much was contributed each year/month for ESOP. 
Distinguish if this was participant, forfeiture, or source and which fund it was for. 
Separate out positive and negative shares*/
SELECT 
	Plan_number
	,YEAR(Calendar_day) AS CalendarDate
	,MONTH(Calendar_day) AS Months
	,Transact
	,Transaction_type
	,CASE WHEN SSN = '999-99-9999F' THEN 'Forfeiture'
		WHEN SSN = '999-99-9999S' THEN 'Suspense'
		ELSE 'Participant' END AS Account
	,CASE 
		WHEN FUND LIKE 'SA2A%' THEN 'UHAL'
		WHEN FUND IN ('SA2F-AMERCO SERIES N STCK') THEN 'UHAL.B'
		WHEN FUND IN ('0458-FID GOVT MMKT') THEN 'MMKT'
		ELSE 'Unknown' END AS Funds
	,SUM(CASE WHEN Cash_amount > 0 THEN Cash_amount END) AS PositiveCashTotal
	,SUM(CASE WHEN Cash_amount < 0 THEN Cash_amount END) AS NegativeCashTotal
	,SUM(CASE WHEN Share_amount > 0 THEN Share_amount END) AS PositiveShareTotal
	,SUM(CASE WHEN Share_amount < 0 THEN Share_amount END) AS NegativeShareTotal
FROM [DevRaw].[dbo].[Audit_Participant_Level_Activity_Report]
WHERE Plan_number = '75952'
	AND Transaction_type = '1-Contributions'
GROUP BY Plan_number ,YEAR(Calendar_day) ,Transact ,Transaction_type, MONTH(Calendar_day)
	,CASE 
		WHEN FUND LIKE 'SA2A%' THEN 'UHAL'
		WHEN FUND IN ('SA2F-AMERCO SERIES N STCK') THEN 'UHAL.B'
		WHEN FUND IN ('0458-FID GOVT MMKT') THEN 'MMKT'
		ELSE 'Unknown' END
	,CASE WHEN SSN = '999-99-9999F' THEN 'Forfeiture'
		WHEN SSN = '999-99-9999S' THEN 'Suspense'
		ELSE 'Participant' END

--hrsdbssqlwp0003.uhaul.amerco.org