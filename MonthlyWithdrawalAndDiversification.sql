/*Monthly Withdawal and Diversification information.
This will show the unique count of people that diversified/withdrew both A and B shares, only A shares, or only B shares.
Will also grab a sum of how many shares this was done for each month. 
Add an identified for status group.
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
		AND Fund = 'SA2A-AMERCO STOCK'
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

--Identify transactions that had both UHAL and UHALB shares. Find a unique count each month, and a total share count (combined).
,BOTH_Shares AS (
SELECT 
	YEAR(CalendarDays) AS Years
	,MONTH(CalendarDays) AS Months
	,Transaction_type
	,Stati_Group
	,COUNT (DISTINCT SSNs) AS Unique_Both
--Combine the total of both shares together
	,(SUM(UHAL_Shares) + SUM(UHALB_Shares)) AS BothShareTotal
FROM Transactions
--Both share types must not be null to qualify.
WHERE 
	UHAL_Shares IS NOT NULL
	AND UHALB_Shares IS NOT NULL
GROUP BY 
	YEAR(CalendarDays)
	,MONTH(CalendarDays)
	,Transaction_type
	,Stati_Group
)

--Identify transactions that had only UHAL shares, no UHALB. Find a unique count each month, and a total share count.
,UHAL_A_Only AS (
SELECT 
	YEAR(CalendarDays) AS Years
	,MONTH(CalendarDays) AS Months
	,Transaction_type
	,Stati_Group
	,COUNT (DISTINCT SSNs) AS Unique_A_Count
	,(SUM(UHAL_Shares)) AS A_ShareTotal
FROM Transactions
--UHAL must not be null, but UHALB must be null or have nothing happening.
WHERE 
	UHAL_Shares IS NOT NULL
	AND UHALB_Shares IS NULL
GROUP BY 
	YEAR(CalendarDays)
	,MONTH(CalendarDays)
	,Transaction_type
	,Stati_Group
)

--Identify transactions that had only UHALB shares, no UHAL. Find a unique count each month, and a total share count.
,UHAL_B_Only AS (
SELECT 
	YEAR(CalendarDays) AS Years
	,MONTH(CalendarDays) AS Months
	,Transaction_type
	,Stati_Group
	,COUNT (DISTINCT SSNs) AS Unique_B_Count
	,(SUM(UHALB_Shares)) AS B_ShareTotal
FROM Transactions
--UHALB must not be null, but UHAL must be null or have nothing happening.
WHERE 
	UHAL_Shares IS NULL
	AND UHALB_Shares IS NOT NULL
GROUP BY 
	YEAR(CalendarDays)
	,MONTH(CalendarDays)
	,Transaction_type
	,Stati_Group
)

--Combine outputs from UHAL A only and UHALB only. Use A as a priority for years and months and statuses. Should all be the same though.
,Merge_A_B AS (
SELECT 
--Using A transactions as the priority before B.
	COALESCE(UHAL_A_Only.Years, UHAL_B_Only.Years) AS Years
	,COALESCE(UHAL_A_Only.Months, UHAL_B_Only.Months) AS Months
	,COALESCE(UHAL_A_Only.Stati_Group, UHAL_B_Only.Stati_Group) AS Stati_Group
	,COALESCE(UHAL_A_Only.Transaction_type, UHAL_B_Only.Transaction_type) AS Transaction_type
	,Unique_A_Count
	,A_ShareTotal
	,Unique_B_Count
	,B_ShareTotal
FROM UHAL_A_Only
FULL JOIN UHAL_B_Only
	ON UHAL_A_Only.Years = UHAL_B_Only.Years
	AND UHAL_A_Only.Months = UHAL_B_Only.Months
	AND UHAL_A_Only.Stati_Group = UHAL_B_Only.Stati_Group
	AND UHAL_A_Only.Transaction_type = UHAL_B_Only.Transaction_type
)

--Combine the merged A&B table with the Both shares table.
SELECT 
	COALESCE(BOTH_Shares.Years,Merge_A_B.Years) AS Years
	,COALESCE(BOTH_Shares.Months, Merge_A_B.Months) AS Months
	,COALESCE(BOTH_Shares.Stati_Group, Merge_A_B.Stati_Group) AS Stati_Group
	,COALESCE(BOTH_Shares.Transaction_type, Merge_A_B.Transaction_type) AS Transaction_type
	,Unique_Both
	,BothShareTotal
	,Unique_A_Count
	,A_ShareTotal
	,Unique_B_Count
	,B_ShareTotal
FROM BOTH_Shares
FULL JOIN Merge_A_B
	ON BOTH_Shares.Years = Merge_A_B.Years
	AND BOTH_Shares.Months = Merge_A_B.Months
	AND BOTH_Shares.Stati_Group = Merge_A_B.Stati_Group
	AND BOTH_Shares.Transaction_type = Merge_A_B.Transaction_type
ORDER BY Years DESC, Months DESC, Stati_Group ASC