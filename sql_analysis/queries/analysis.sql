USE SuperLigDB;
GO
-- ==========================
-- TEAM PERFORMANCE ANALYSIS
-- ==========================

-- 1. Home vs Away Performance
WITH HomePerformance AS
(
	SELECT
		T.TeamID,
		T.TeamName,
		COUNT(*) AS HomePlayed,
		SUM
		(
			CASE 
				WHEN M.HomeGoals > M.AwayGoals 
				THEN 1 ELSE 0 
			END
		) AS HomeWins,
		SUM
		(
			CASE 
				WHEN M.HomeGoals = M.AwayGoals 
				THEN 1 ELSE 0 
			END
		) AS HomeDraws,
		SUM
		(
			CASE 
				WHEN M.HomeGoals < M.AwayGoals 
				THEN 1 ELSE 0
			END
		) AS HomeLosses,
		SUM
		(
			CASE
				WHEN M.HomeGoals > M.AwayGoals
				THEN 3
				WHEN M.HomeGoals = M.AwayGoals
				THEN 1
				ELSE 0
			END
		) AS HomePoints
	FROM Teams AS T
	INNER JOIN Matches AS M
		ON M.HomeTeamID = T.TeamID
	GROUP BY T.TeamID, T.TeamName
),

AwayPerformance AS 
(
	SELECT 
		T.TeamID,
		T.TeamName,
		COUNT(*) AS AwayPlayed,
		SUM
		(
			CASE
				WHEN M.AwayGoals > M.HomeGoals
				THEN 1 ELSE 0
			END
		) AS AwayWins,
		SUM
		(
			CASE
				WHEN M.AwayGoals = M.HomeGoals
				THEN 1 ELSE 0
			END
		) AS AwayDraws,
		SUM
		(
			CASE
				WHEN M.AwayGoals < M.HomeGoals
				THEN 1 ELSE 0
			END
		) AS AwayLosses,
		SUM
		(
			CASE
				WHEN M.AwayGoals > M.HomeGoals
				THEN 3
				WHEN M.AwayGoals = M.HomeGoals
				THEN 1
				ELSE 0
			END
		) AS AwayPoints
	FROM Teams AS T
	INNER JOIN Matches AS M
		ON M.AwayTeamID = T.TeamID
	GROUP BY T.TeamID, T.TeamName
)

SELECT 
	H.TeamName,
	H.HomePlayed,
	H.HomeWins,
	H.HomeDraws,
	H.HomeLosses,
	H.HomePoints,
	CAST(H.HomeWins * 100.0 / H.HomePlayed AS DECIMAL(5,2)) AS HomeWinRate,
	A.AwayPlayed,
	A.AwayWins,
	A.AwayDraws,
	A.AwayLosses,
	A.AwayPoints,
	CAST(A.AwayWins * 100.0 / A.AwayPlayed AS DECIMAL(5,2)) AS AwayWinRate,
	H.HomePoints - A.AwayPoints AS PointsDifference
FROM HomePerformance AS H
INNER JOIN AwayPerformance AS A
	ON H.TeamID = A.TeamID
ORDER BY PointsDifference DESC;

-- 2. Attacking Performance
SELECT 
	T.TeamName,
	TSS.MatchesPlayed AS TotalMatches,
	TSS.GoalsFor AS TotalGoals,
	CAST(TSS.GoalsFor * 1.0 / TSS.MatchesPlayed AS DECIMAL (5,2)) AS GoalsPerMatch,
	SUM
	(
		CASE
			WHEN M.HomeGoals = 0
				AND M.HomeTeamID = T.TeamID
			THEN 1
			WHEN M.AwayGoals = 0
				AND M.AwayTeamID = T.TeamID
			THEN 1
			ELSE 0
		END
	) AS ScorelessMatches,
	SUM
	(
		CASE 
			WHEN M.HomeGoals >= 1
				AND M.HomeTeamID = T.TeamID
			THEN 1
			WHEN M.AwayGoals >= 1
				AND M.AwayTeamID = T.TeamID
			THEN 1
			ELSE 0
		END
	) AS ScoringMatches,
	CAST(SUM
	(
		CASE 
			WHEN M.HomeGoals >= 1
				AND M.HomeTeamID = T.TeamID
			THEN 1
			WHEN M.AwayGoals >= 1
				AND M.AwayTeamID = T.TeamID
			THEN 1
			ELSE 0
		END
	) * 100.0 / TSS.MatchesPlayed AS DECIMAL (5,2)) AS ScoringRate,
	MAX
	(
		CASE
			WHEN M.HomeTeamID = T.TeamID
			THEN M.HomeGoals
			WHEN M.AwayTeamID = T.TeamID
			THEN M.AwayGoals
			ELSE 0
		END
	) AS MaxGoalsScored
FROM Teams AS T
INNER JOIN TeamSeasonStats AS TSS
	ON TSS.TeamID = T.TeamID
INNER JOIN Matches AS M
	ON M.HomeTeamID = T.TeamID
	OR M.AwayTeamID = T.TeamID
GROUP BY
	T.TeamID,
	T.TeamName,
	TSS.GoalsFor,
	TSS.MatchesPlayed
ORDER BY GoalsPerMatch DESC;

-- 3. Defensive Performance
SELECT
	T.TeamName,
	TSS.MatchesPlayed AS TotalMatches,
	TSS.GoalsAgainst AS TotalGoalsConceded,
	CAST(TSS.GoalsAgainst * 1.0 / TSS.MatchesPlayed AS DECIMAL (5,2)) AS GoalsConcededPerMatch,
	SUM
	(
		CASE
			WHEN M.HomeGoals = 0
				AND M.AwayTeamID = T.TeamID
			THEN 1
			WHEN M.AwayGoals = 0
				AND M.HomeTeamID = T.TeamID
			THEN 1
			ELSE 0
		END
	) AS CleanSheets,
	CAST(SUM
	(
		CASE
			WHEN M.HomeGoals = 0
				AND M.AwayTeamID = T.TeamID
			THEN 1
			WHEN M.AwayGoals = 0
				AND M.HomeTeamID = T.TeamID
			THEN 1
			ELSE 0
		END
	) * 100.0 / TSS.MatchesPlayed AS DECIMAL (5,2)) AS CleanSheetRate,
	MAX
	(
		CASE
			WHEN M.HomeTeamID = T.TeamID
			THEN M.AwayGoals
			WHEN M.AwayTeamID = T.TeamID
			THEN M.HomeGoals
			ELSE 0
		END
	) AS MaxGoalsConceded
FROM Teams AS T
INNER JOIN TeamSeasonStats AS TSS
	ON TSS.TeamID = T.TeamID
INNER JOIN Matches AS M
	ON M.HomeTeamID = T.TeamID
	OR M.AwayTeamID = T.TeamID
GROUP BY 
	T.TeamID,
	T.TeamName,
	TSS.GoalsAgainst,
	TSS.MatchesPlayed
ORDER BY GoalsConcededPerMatch;

-- 4. Performance Against Top 5 Teams
WITH Top5Teams AS
(
	SELECT TeamID
	FROM TeamSeasonStats
	WHERE LeaguePosition <= 5
),

Top5Analysis AS
(
	SELECT
		T.TeamName,
		TSS.LeaguePosition,
		SUM
		(
			CASE 
				WHEN M.HomeTeamID = T.TeamID
					AND M.AwayTeamID = TT.TeamID
				THEN 1
				WHEN M.AwayTeamID = T.TeamID
					AND M.HomeTeamID = TT.TeamID
				THEN 1
				ELSE 0
			END
		) AS MatchesVsTop5,
		SUM
		(
			CASE 
				WHEN M.HomeTeamID = T.TeamID
					AND M.AwayTeamID = TT.TeamID
					AND M.HomeGoals > M.AwayGoals
				THEN 1
				WHEN M.AwayTeamID = T.TeamID
					AND M.HomeTeamID = TT.TeamID
					AND M.AwayGoals > M.HomeGoals
				THEN 1
				ELSE 0
			END
		) AS WinsVsTop5,
		SUM
		(
			CASE 
				WHEN M.HomeTeamID = T.TeamID
					AND M.AwayTeamID = TT.TeamID
					AND M.HomeGoals = M.AwayGoals
				THEN 1
				WHEN M.AwayTeamID = T.TeamID
					AND M.HomeTeamID = TT.TeamID
					AND M.AwayGoals = M.HomeGoals
				THEN 1
				ELSE 0
			END
		) AS DrawsVsTop5,
		SUM
		(
			CASE 
				WHEN M.HomeTeamID = T.TeamID
					AND M.AwayTeamID = TT.TeamID
					AND M.HomeGoals < M.AwayGoals
				THEN 1
				WHEN M.AwayTeamID = T.TeamID
					AND M.HomeTeamID = TT.TeamID
					AND M.AwayGoals < M.HomeGoals
				THEN 1
				ELSE 0
			END
		) AS LossesVsTop5,
		SUM
		(
			CASE 
				WHEN M.HomeTeamID = T.TeamID
					AND M.AwayTeamID = TT.TeamID
					AND M.HomeGoals > M.AwayGoals
				THEN 3
				WHEN M.HomeTeamID = T.TeamID
					AND M.AwayTeamID = TT.TeamID
					AND M.HomeGoals = M.AwayGoals
				THEN 1
				WHEN M.AwayTeamID = T.TeamID
					AND M.HomeTeamID = TT.TeamID
					AND M.AwayGoals > M.HomeGoals
				THEN 3
				WHEN M.AwayTeamID = T.TeamID
					AND M.HomeTeamID = TT.TeamID
					AND M.AwayGoals = M.HomeGoals
				THEN 1
				ELSE 0
			END
		) AS PointsVsTop5
	FROM Teams AS T
	INNER JOIN Matches AS M
		ON M.HomeTeamID = T.TeamID
		OR M.AwayTeamID = T.TeamID
	INNER JOIN Top5Teams AS TT
		ON TT.TeamID = T.TeamID
		OR TT.TeamID = M.HomeTeamID
		OR TT.TeamID = M.AwayTeamID
	INNER JOIN TeamSeasonStats AS TSS
		ON TSS.TeamID = T.TeamID
	GROUP BY
		T.TeamID,
		T.TeamName,
		TSS.LeaguePosition
)

SELECT 
	TeamName,
	LeaguePosition,
	MatchesVsTop5,
	WinsVsTop5,
	DrawsVsTop5,
	LossesVsTop5,
	PointsVsTop5,
	CAST(PointsVsTop5 * 1.0 / MatchesVsTop5 AS DECIMAL (5,2)) AS PPGVsTop5
FROM Top5Analysis
ORDER BY PPGVsTop5 DESC;

-- 5. First vs Second Half of the Season Performance
WITH HalfSeasonPerformance AS
(
	SELECT
		TSS.LeaguePosition,
		T.TeamName,
		SUM
		(
			CASE
				WHEN M.MatchWeek <= 17
					AND M.HomeTeamID = T.TeamID
					AND M.HomeGoals > M.AwayGoals
				THEN 1
				WHEN M.MatchWeek <= 17
					AND M.AwayTeamID = T.TeamID
					AND M.AwayGoals > M.HomeGoals
				THEN 1
				ELSE 0
			END
		) AS FirstHalfWins,
		SUM
		(
			CASE
				WHEN M.MatchWeek <= 17
					AND M.HomeGoals = M.AwayGoals
				THEN 1
				ELSE 0
			END
		) AS FirstHalfDraws,
		SUM
		(
			CASE
				WHEN M.MatchWeek <= 17
					AND M.HomeTeamID = T.TeamID
					AND M.HomeGoals < M.AwayGoals
				THEN 1
				WHEN M.MatchWeek <= 17
					AND M.AwayTeamID = T.TeamID
					AND M.AwayGoals < M.HomeGoals
				THEN 1
				ELSE 0
			END
		) AS FirstHalfLosses,
		SUM
		(
			CASE
				WHEN M.MatchWeek > 17
					AND M.HomeTeamID = T.TeamID
					AND M.HomeGoals > M.AwayGoals
				THEN 1
				WHEN M.MatchWeek > 17
					AND M.AwayTeamID = T.TeamID
					AND M.AwayGoals > M.HomeGoals
				THEN 1
				ELSE 0
			END
		) AS SecondHalfWins,
		SUM
		(
			CASE
				WHEN M.MatchWeek > 17
					AND M.HomeGoals = M.AwayGoals
				THEN 1
				ELSE 0
			END
		) AS SecondHalfDraws,
		SUM
		(
			CASE
				WHEN M.MatchWeek > 17
					AND M.HomeTeamID = T.TeamID
					AND M.HomeGoals < M.AwayGoals
				THEN 1
				WHEN M.MatchWeek > 17
					AND M.AwayTeamID = T.TeamID
					AND M.AwayGoals < M.HomeGoals
				THEN 1
				ELSE 0
			END
		) AS SecondHalfLosses
	FROM Teams AS T
	INNER JOIN TeamSeasonStats AS TSS
		ON T.TeamID = TSS.TeamID
	INNER JOIN Matches AS M
		ON M.HomeTeamID = T.TeamID
		OR M.AwayTeamID = T.TeamID
	GROUP BY
		T.TeamID,
		T.TeamName,
		TSS.LeaguePosition
)

SELECT
	TeamName,
	LeaguePosition,
	FirstHalfWins,
	FirstHalfDraws,
	FirstHalfLosses,
	FirstHalfWins * 3 + FirstHalfDraws AS FirstHalfPoints,
	SecondHalfWins,
	SecondHalfDraws,
	SecondHalfLosses,
	SecondHalfWins * 3 + SecondHalfDraws AS SecondHalfPoints,
	(SecondHalfWins * 3 + SecondHalfDraws)
		- (FirstHalfWins * 3 + FirstHalfDraws) AS PointsDifference
FROM HalfSeasonPerformance
ORDER BY PointsDifference DESC;

-- ===========================
-- PLAYER PERFORMANCE ANALYSIS
-- ===========================

-- 1. Goal Contribution Efficiency
SELECT TOP 20
	P.PlayerName,
	STRING_AGG(T.TeamName, ', ') AS Teams,
	STRING_AGG(CAST(TSS.LeaguePosition AS VARCHAR(2)), ', ') AS LeaguePositions,
	PSS.Position,
	SUM(PSS.MatchesPlayed) AS TotalMatches,
	SUM(PSS.MatchesStarted) AS MatchesStarted,
	SUM(PSS.Minutes) AS TotalMinutes,
	SUM(PSS.Goals) AS TotalGoals,
	SUM(PSS.Assists) AS TotalAssists,
	SUM(PSS.Goals + PSS.Assists) AS GoalContributions,
	CAST(SUM(PSS.Minutes) * 1.0 / NULLIF(SUM(PSS.Goals),0) AS DECIMAL (10,2)) AS MinsPerGoal,
	CAST(SUM(PSS.Minutes) * 1.0 / NULLIF(SUM(PSS.Assists),0) AS DECIMAL (10,2)) AS MinsPerAssist,
	CAST(SUM(PSS.Minutes) * 1.0 / NULLIF(SUM(PSS.Goals + PSS.Assists),0) AS DECIMAL (10,2)) AS MinsPerGoalContribution
FROM Players AS P
INNER JOIN PlayerSeasonStats AS PSS
	ON PSS.PlayerID = P.PlayerID
INNER JOIN Teams AS T
	ON T.TeamID = PSS.TeamID
INNER JOIN TeamSeasonStats AS TSS
	ON TSS.TeamID = PSS.TeamID
GROUP BY
	P.PlayerID,
	P.PlayerName,
	PSS.Position
HAVING SUM(PSS.Minutes) >= 900
ORDER BY
    CASE WHEN SUM(PSS.Goals + PSS.Assists) = 0 THEN 1 ELSE 0 END,
    MinsPerGoalContribution ASC;

-- 2. Team Dependency
WITH RankedPlayers AS
(
	SELECT 
		PSS.PlayerID,
		PSS.TeamID,
		PSS.Goals,
		PSS.Assists,
		PSS.Goals + PSS.Assists AS GoalContributions, 
		ROW_NUMBER() OVER
		(
			PARTITION BY PSS.TeamID
			ORDER BY 
				PSS.Goals + PSS.Assists DESC,
				PSS.Goals DESC,
				PSS.PlayerID
		) AS RowNum
	FROM PlayerSeasonStats AS PSS
)

SELECT
	T.TeamName,
	TSS.LeaguePosition,
	P.PlayerName,
	TSS.GoalsFor AS TeamGoals,
	RP.Goals AS PlayerGoals,
	RP.Assists AS PlayerAssists,
	RP.GoalContributions,
	CAST(RP.GoalContributions * 100.0 / TSS.GoalsFor AS DECIMAL (10,2)) AS ContributionPercentage
FROM Teams AS T
INNER JOIN TeamSeasonStats AS TSS
	ON TSS.TeamID = T.TeamID
INNER JOIN RankedPlayers AS RP
	ON RP.TeamID = T.TeamID
INNER JOIN Players AS P
	ON P.PlayerID = RP.PlayerID
WHERE RP.RowNum = 1
ORDER BY ContributionPercentage DESC;

-- 3. Hidden Gems
SELECT TOP 15
	P.PlayerName,
	STRING_AGG(T.TeamName, ', ') AS Teams,
	SUM(PSS.MatchesPlayed) AS MatchesPlayed,
	SUM(PSS.MatchesStarted) AS MatchesStarted,
	SUM(PSS.Minutes) AS TotalMinutes,
	SUM(PSS.Goals) AS TotalGoals,
	SUM(PSS.Assists) AS TotalAssists,
	SUM(PSS.Goals + PSS.Assists) AS GoalContribution,
	CAST(SUM(PSS.Minutes) * 1.0 / SUM(PSS.Goals + PSS.Assists) AS DECIMAL (10,2)) AS MinsPerGoalContribution
FROM Players AS P
INNER JOIN PlayerSeasonStats AS PSS
	ON PSS.PlayerID = P.PlayerID
INNER JOIN Teams AS T
	ON T.TeamID = PSS.TeamID
GROUP BY
	P.PlayerID,
	P.PlayerName
HAVING
	SUM(PSS.Goals + PSS.Assists) >= 3
	AND SUM(PSS.Minutes) BETWEEN 300 AND 899
ORDER BY MinsPerGoalContribution; 

-- ===============
-- MATCH ANALYSIS
-- ===============

-- 1. Points Dropped Against Bottom 5 Teams
WITH Top5Teams AS
(
    SELECT 
		T.TeamID, 
		T.TeamName,
		TSS.LeaguePosition,
		TSS.Points AS SeasonPoints
    FROM TeamSeasonStats AS TSS
    INNER JOIN Teams AS T
        ON T.TeamID = TSS.TeamID
    WHERE TSS.LeaguePosition BETWEEN 1 AND 5
),
Bottom5Teams AS
(
    SELECT TeamID
    FROM TeamSeasonStats
    WHERE LeaguePosition BETWEEN 14 AND 18
)
SELECT
    TT.TeamName,
	TT.LeaguePosition,
	TT.SeasonPoints,
    COUNT(*) AS MatchesPlayed,
    SUM
	(
        CASE
            WHEN M.HomeTeamID = TT.TeamID 
				AND M.HomeGoals > M.AwayGoals 
			THEN 1
            WHEN M.AwayTeamID = TT.TeamID 
				AND M.AwayGoals > M.HomeGoals 
			THEN 1
            ELSE 0
        END
    ) AS Wins,
    SUM
	(
        CASE 
			WHEN M.HomeGoals = M.AwayGoals 
			THEN 1 
			ELSE 0 
		END
    ) AS Draws,
    SUM
	(
        CASE
            WHEN M.HomeTeamID = TT.TeamID 
				AND M.HomeGoals < M.AwayGoals 
			THEN 1
            WHEN M.AwayTeamID = TT.TeamID 
				AND M.AwayGoals < M.HomeGoals 
			THEN 1
            ELSE 0
        END
    ) AS Losses,
    SUM
	(
        CASE
            WHEN M.HomeTeamID = TT.TeamID 
				AND M.HomeGoals > M.AwayGoals 
			THEN 3
            WHEN M.AwayTeamID = TT.TeamID 
				AND M.AwayGoals > M.HomeGoals 
			THEN 3
            WHEN M.HomeGoals = M.AwayGoals 
			THEN 1
            ELSE 0
        END
    ) AS PointsEarned,
    COUNT(*) * 3 -
    SUM
	(
        CASE
            WHEN M.HomeTeamID = TT.TeamID 
				AND M.HomeGoals > M.AwayGoals 
			THEN 3
            WHEN M.AwayTeamID = TT.TeamID 
				AND M.AwayGoals > M.HomeGoals 
			THEN 3
            WHEN M.HomeGoals = M.AwayGoals 
			THEN 1
            ELSE 0
        END
    ) AS PointsDropped
FROM Top5Teams AS TT
INNER JOIN Matches AS M
    ON M.HomeTeamID = TT.TeamID 
	OR M.AwayTeamID = TT.TeamID
WHERE
    M.HomeTeamID IN (SELECT TeamID FROM Bottom5Teams)
    OR M.AwayTeamID IN (SELECT TeamID FROM Bottom5Teams)
GROUP BY
    TT.TeamID,
    TT.TeamName,
	TT.LeaguePosition,
	TT.SeasonPoints
ORDER BY
    PointsDropped DESC;

-- 2. Close Match Performance
WITH CloseMatches AS
(
	SELECT
		T.TeamName,
		TSS.LeaguePosition,
		TSS.Win,
		TSS.Lose,
		SUM
		(
			CASE
				WHEN T.TeamID = M.HomeTeamID
					AND M.HomeGoals - M.AwayGoals = 1
				THEN 1
				WHEN T.TeamID = M.AwayTeamID
					AND M.AwayGoals - M.HomeGoals = 1
				THEN 1
				ELSE 0
			END
		) AS CloseWins,
		SUM
		(
			CASE
				WHEN T.TeamID = M.HomeTeamID
					AND M.HomeGoals - M.AwayGoals = -1
				THEN 1
				WHEN T.TeamID = M.AwayTeamID
					AND M.AwayGoals - M.HomeGoals = -1
				THEN 1
				ELSE 0
			END
		) AS CloseLosses
	FROM Teams AS T
	INNER JOIN Matches AS M
		ON M.HomeTeamID = T.TeamID
		OR M.AwayTeamID = T.TeamID
	INNER JOIN TeamSeasonStats AS TSS
		ON TSS.TeamID = T.TeamID
	GROUP BY 
		T.TeamID,
		T.TeamName,
		TSS.LeaguePosition,
		TSS.Win,
		TSS.Lose
)

SELECT
	TeamName,
	LeaguePosition,
	Win,
	CloseWins,
	CAST(CloseWins * 100.0 / Win AS DECIMAL (10,2)) AS CloseWinPercentage,
	Lose,
	CloseLosses,
	CAST(CloseLosses * 100.0 / Lose AS DECIMAL (10,2)) AS CloseLosePercentage
FROM CloseMatches
ORDER BY CloseWins DESC;















