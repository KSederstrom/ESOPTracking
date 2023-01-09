/*Balances_ShareCounts
Make a report that will show a count of people each monthend. 
Will need to also count active and terminated participants.
Also count how many shares and participants are under the UHAL and UHALB shares.
*/
WITH Balances AS (
SELECT
	COALESCE(UHAL.Plan_number, UHALB.Plan_number) AS Plan_number
	,COALESCE(UHAL.SSN, UHALB.SSN) AS SSNs
	,COALESCE(UHAL.Smid, UHALB.Smid) AS SMIDS
	,COALESCE(UHAL.Calendar_day, UHALB.Calendar_day)	AS CalendarDays
	,COALESCE(UHAL.full_name, UHALB.full_name) AS full_name
	,UHAL.Market_value AS UHAL_MKT
	,UHAL.Share_balance AS UHAL_Shares
	,UHALB.Market_value AS UHALB_MKT
	,UHALB.Share_balance AS UHALB_Shares
--Subquery to grab everyone and balances if the fund is UHAL shares only. 
FROM (
	SELECT Plan_number, Calendar_day, SSN, Smid, full_name, Fund, Market_value, Share_balance 
	FROM [DevRaw].[dbo].[Fund_Balances_n_CostBasis_EOM]
	WHERE Plan_number = '75952'
		AND Fund LIKE 'SA2A%'
	) AS UHAL
--LEFT JOIN a Subquery that grabs everyone and balances if the fund is UHALB shares only. 
FULL JOIN (
	SELECT 	Plan_number, Calendar_day, SSN, Smid, full_name, Fund, Market_value, Share_balance 
	FROM [DevRaw].[dbo].[Fund_Balances_n_CostBasis_EOM]
	WHERE Plan_number = '75952'
		AND Fund LIKE 'SA2F%'
	) AS UHALB
--Joining on SSNs and Calendar Day Should be enough.	
	ON UHAL.SSN = UHALB.SSN
	AND UHAL.Calendar_day = UHALB.Calendar_day
	)

--Grab everyone from the demographic once each month along with status. 
--Link to itself for ESOP and 401k in case someone is only in one plan/information (statuses) only in one plan. 401k has priority
,Demo AS (
SELECT 
	COALESCE(K.Plan_number, E.Plan_number) AS Plans
	,COALESCE(K.Calendar_day, E.Calendar_day) AS Calendar_Date
	,COALESCE(K.SSN, E.SSN) AS SSNs
	,COALESCE(K.Full_name,E.Full_name) AS Names
	,COALESCE(K.Status_historical,E.Status_historical) AS Stati
--Create a grouping of three options. Plan accounts, active,  or termed. If no status, term. Use the 401k status first, then the ESOP if nothing is available.
	,CASE WHEN COALESCE(K.SSN, E.SSN) IN ('999-99-9999F','999-99-9999J','999-99-9999L','999-99-9999S') THEN 'Plan'
		WHEN COALESCE(K.Status_historical,E.Status_historical) IN ('A-ACTIVE', 'Active', 'E-ELIGIBLE', 'H-REHIRE', 'L-LEAVE OF ABSENCE', 'N-NEW HIRE', 'On Leave', 'U-MILITARY LEAVE')
			THEN 'Active'
		WHEN COALESCE(K.Status_historical,E.Status_historical) IN ('B-BENEFICIARY-SPOUSE', 'Y-NON-SPOUSE BENE', 'D-DECEASED', 'Q-QDRO SPOUSAL', 'V-QDRO NON-SPOUSAL',
			'R-RETIRED', 'Terminated', 'T-TERMINATED')
			THEN 'Termed'
		ELSE 'Termed' END AS Stati_Group
	,COALESCE(K.Birth_date, E.Birth_date) AS BirthDates
	,DATEDIFF(MONTH,COALESCE(K.Birth_date, E.Birth_date),COALESCE(K.Calendar_day, E.Calendar_day))/12.0 AS Ages
--Sub to grab demographic info on 401k, quarterly.
FROM (
	SELECT * FROM [DevRaw].[dbo].[Demographic_Data_EOM] WHERE Plan_number = '75951'
	) AS K
--Sub to grab demographic info on ESOP, quarterly.
FULL JOIN (
	SELECT * FROM [DevRaw].[dbo].[Demographic_Data_EOM] WHERE Plan_number = '75952'
	) AS E
	ON K.SSN = E.SSN
	AND K.Calendar_day = E.Calendar_day
)

,Merged AS (
SELECT 
	Balances.Plan_number
	,Balances.CalendarDays
	,Balances.SSNs
	,Balances.SMIDS
	,Balances.full_name
	,demo.Stati_Group
	,demo.Stati
	,UHAL_MKT
	,UHAL_Shares
	,UHALB_MKT
	,UHALB_Shares
FROM Balances
LEFT JOIN DEMO
ON Balances.SSNs = demo.SSNs
	AND Balances.CalendarDays = demo.Calendar_Date
	)

SELECT 
	CalendarDays
--UNique Count of all participants regardless of status or stock type.
	,COUNT (DISTINCT SSNs) ALL_ESOPHolders_Counts
--Count of All participants that are active regardless of stock type.
	,COUNT (CASE WHEN Stati_Group = 'Active' THEN 1 ELSE NULL END) AS Active_Count
--Count of all participants that are terminated regardless of stock type.
	,COUNT (CASE WHEN Stati_Group = 'Termed' THEN 1 ELSE NULL END) AS Termed_Count
--Count of all participants that are terminated regardless of stock type.
	,COUNT (CASE WHEN Stati_Group = 'Plan' THEN 1 ELSE NULL END) AS Plan_Count
--Count of all participants that have UHAL shares only.
	,COUNT (CASE WHEN UHAL_Shares > 0 AND UHALB_Shares IS NULL THEN 1 ELSE NULL END) AS UHAL_Only_Count
--Count of all participants that have UHALB shares only.
	,COUNT (CASE WHEN UHAL_Shares = 0 AND UHALB_Shares > 0 THEN 1 ELSE NULL END) AS UHALB_Only_Count
--Count of all participants that have both UHAL and UHALB shares.
	,COUNT (CASE WHEN UHAL_Shares > 0 AND UHALB_Shares > 0 THEN 1 ELSE NULL END) AS BothStocks_Count
FROM Merged
GROUP BY CalendarDays
ORDER BY CalendarDays DESC

