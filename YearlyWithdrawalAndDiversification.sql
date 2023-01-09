/*Yearly Withdawal and Diversification information.
Grab unique coutn of people and total shares under ESOP that are withdrawan or diversified yearly.
Does not distinguish between the two share types.
*/

SELECT 
	Plan_number
    ,YEAR(Calendar_day) AS Years
   ,CASE
		WHEN FUND LIKE 'SA2A%' THEN 'UHAL'
		WHEN FUND IN ('SA2F-AMERCO SERIES N STCK') THEN 'UHAL.B'
		WHEN FUND IN ('0458-FID GOVT MMKT') THEN 'MMKT'
		ELSE 'Unknown' END AS Funds
    ,Transaction_type
	,COUNT(DISTINCT SSN) AS TM_Counts
	,SUM(Share_amount) AS Shares
FROM [DevRaw].[dbo].[Audit_Participant_Level_Activity_Report]
WHERE 
	Plan_number = '75952'
	AND Transaction_type IN ('9-Withdrawal','12-Exchange Out')
	AND Fund IN ('SA2A-AMERCO STOCK','SA2F-AMERCO SERIES N STCK')
GROUP BY 
	Plan_number
    ,YEAR(Calendar_day)
    ,Fund
    ,Transaction_type
	,CASE
		WHEN FUND LIKE 'SA2A%' THEN 'UHAL'
		WHEN FUND IN ('SA2F-AMERCO SERIES N STCK') THEN 'UHAL.B'
		WHEN FUND IN ('0458-FID GOVT MMKT') THEN 'MMKT'
		ELSE 'Unknown' END
ORDER BY YEAR(Calendar_day) DESC, Transaction_type ASC