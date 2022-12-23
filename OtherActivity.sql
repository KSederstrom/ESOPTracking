--Track activity each year/month for ESOP. 
--Distinguish if this was participant, forfeiture, or source and which fund it was for. 
--Separate out positive and negative shares.
SELECT Plan_number
	,YEAR(Calendar_day) AS CalendarDate
	,MONTH(Calendar_day) AS Months
	,Transact
	,Transaction_type
	,Fund
	,SUM(Cash_amount) AS CashTotal
	,SUM(Share_amount) AS ShareTotal
	,CASE WHEN SSN = '999-99-9999F' THEN 'Forfeiture'
		WHEN SSN = '999-99-9999S' THEN 'Suspense'
		ELSE 'Participant' END AS Account
FROM [DevRaw].[dbo].[Audit_Participant_Level_Activity_Report]
WHERE Plan_number = '75952'
--	AND Transaction_type <> '1-Contributions'
GROUP BY Plan_number ,YEAR(Calendar_day) ,Transact ,Transaction_type ,Fund, MONTH(Calendar_day)
	,CASE WHEN SSN = '999-99-9999F' THEN 'Forfeiture'
		WHEN SSN = '999-99-9999S' THEN 'Suspense'
		ELSE 'Participant' END
