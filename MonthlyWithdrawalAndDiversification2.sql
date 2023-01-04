/*Monthly Withdawal and Diversification information 2.
This will show the sum of shares that were diversified/withdrew by type. 
*/
WITH Transactions AS (
SELECT
	COALESCE(UHAL.Plan_number, UHALB.Plan_number) AS Plan_number
	,COALESCE(UHAL.SSN, UHALB.SSN) AS SSNs
	,CASE WHEN COALESCE(UHAL.SSN, UHALB.SSN) IN ('999-99-9999F','999-99-9999J','999-99-9999L','999-99-9999S') THEN 'Plan'
		WHEN COALESCE(UHAL.Status, UHALB.Status) IN ('A-ACTIVE', 'Active', 'E-ELIGIBLE', 'H-REHIRE', 'L-LEAVE OF ABSENCE', 'N-NEW HIRE', 'On Leave', 'U-MILITARY LEAVE')
			THEN 'Active'
		WHEN COALESCE(UHAL.Status, UHALB.Status) IN ('B-BENEFICIARY-SPOUSE', 'Y-NON-SPOUSE BENE', 'D-DECEASED', 'Q-QDRO SPOUSAL', 'V-QDRO NON-SPOUSAL',
			'R-RETIRED', 'Terminated', 'T-TERMINATED')
			THEN 'Termed'
		ELSE 'Termed' END AS Stati_Group
	,COALESCE(UHAL.Status, UHALB.Status) AS Status
	,COALESCE(UHAL.Calendar_day, UHALB.Calendar_day) AS CalendarDays
	,COALESCE(UHAL.full_name, UHALB.full_name) AS full_name
	,COALESCE(UHAL.Transaction_type, UHALB.Transaction_type) AS Transaction_type
	,UHAL.Share_amount AS UHAL_Shares
	,UHALB.Share_amount AS UHALB_Shares
--Subquery to grab everyone and balances if the fund is UHAL shares only. 
FROM (
	SELECT Plan_number, Calendar_day, SSN, full_name, Fund,Transaction_type, Share_amount, Status
	FROM [DevRaw].[dbo].[Audit_Participant_Level_Activity_Report]
	WHERE Plan_number = '75952'
		AND Fund IN ('SA2A-AMERCO STOCK','SA2A-UHAUL HOLDING CO')
		AND Transaction_type IN ('9-Withdrawal','12-Exchange Out')
	) AS UHAL
--LEFT JOIN a Subquery that grabs everyone and balances if the fund is UHALB shares only. 
FULL JOIN (
	SELECT 	Plan_number, Calendar_day, SSN, full_name, Fund, Transaction_type,Share_amount , Status
	FROM [DevRaw].[dbo].[Audit_Participant_Level_Activity_Report]
	WHERE Plan_number = '75952'
		AND Fund = 'SA2F-AMERCO SERIES N STCK'
		AND Transaction_type IN ('9-Withdrawal','12-Exchange Out')
	) AS UHALB
--Joining on SSNs and Calendar Day Should be enough.	
	ON UHAL.SSN = UHALB.SSN
	AND UHAL.Calendar_day = UHALB.Calendar_day
	AND UHAL.Transaction_type = UHALB.Transaction_type
	AND UHAL.Status = UHALB.Status
	)

SELECT 
	YEAR(CalendarDays) AS YEARS
	,MONTH(CalendarDays) AS Months
	,Transaction_type
	,SUM(UHAL_Shares) AS Total_UHAL_Shares
	,SUM(UHALB_Shares) AS Total_B_Shares
FROM Transactions
GROUP BY 
	YEAR(CalendarDays)
	,MONTH(CalendarDays)
	,Transaction_type
ORDER BY YEAR(CalendarDays) DESC
	,MONTH(CalendarDays) DESC
	,Transaction_type ASC

	