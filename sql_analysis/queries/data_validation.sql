CREATE DATABASE SuperLigDB;
GO

USE SuperLigDB;
GO

-- Data Validation & Referential Integrity Checks
SELECT 'Players' AS TableName, COUNT(*) AS TotalRows FROM dbo.Players
UNION ALL
SELECT 'PlayerSeasonStats', COUNT(*) FROM dbo.PlayerSeasonStats
UNION ALL
SELECT 'Teams', COUNT(*) FROM dbo.Teams
UNION ALL
SELECT 'TeamSeasonStats', COUNT(*) FROM dbo.TeamSeasonStats
UNION ALL
SELECT 'Matches', COUNT(*) FROM dbo.Matches;

SELECT COUNT(*) AS MissingPlayers
FROM dbo.PlayerSeasonStats AS pss
LEFT JOIN dbo.Players AS p
    ON pss.PlayerID = p.PlayerID
WHERE p.PlayerID IS NULL;

SELECT COUNT(*) AS MissingTeams
FROM dbo.PlayerSeasonStats AS pss
LEFT JOIN dbo.Teams AS t
    ON pss.TeamID = t.TeamID
WHERE t.TeamID IS NULL;

SELECT
    SUM(CASE WHEN h.TeamID IS NULL THEN 1 ELSE 0 END) AS MissingHomeTeams,
    SUM(CASE WHEN a.TeamID IS NULL THEN 1 ELSE 0 END) AS MissingAwayTeams
FROM dbo.Matches AS m
LEFT JOIN dbo.Teams AS h
    ON m.HomeTeamID = h.TeamID
LEFT JOIN dbo.Teams AS a
    ON m.AwayTeamID = a.TeamID;

SELECT COUNT(*) AS MissingTeams
FROM dbo.TeamSeasonStats AS tss
LEFT JOIN dbo.Teams AS t
    ON tss.TeamID = t.TeamID
WHERE t.TeamID IS NULL;

-- Foreign Key Constraints
ALTER TABLE dbo.PlayerSeasonStats
ADD CONSTRAINT FK_PlayerSeasonStats_Players
FOREIGN KEY (PlayerID)
REFERENCES dbo.Players(PlayerID);

ALTER TABLE dbo.PlayerSeasonStats
ADD CONSTRAINT FK_PlayerSeasonStats_Teams
FOREIGN KEY (TeamID)
REFERENCES dbo.Teams(TeamID);

ALTER TABLE dbo.TeamSeasonStats
ADD CONSTRAINT FK_TeamSeasonStats_Teams
FOREIGN KEY (TeamID)
REFERENCES dbo.Teams(TeamID);

ALTER TABLE dbo.Matches
ADD CONSTRAINT FK_Matches_HomeTeam
FOREIGN KEY (HomeTeamID)
REFERENCES dbo.Teams(TeamID);

ALTER TABLE dbo.Matches
ADD CONSTRAINT FK_Matches_AwayTeam
FOREIGN KEY (AwayTeamID)
REFERENCES dbo.Teams(TeamID);

-- Primary Key Constraint
ALTER TABLE dbo.PlayerSeasonStats
ADD CONSTRAINT PK_PlayerSeasonStats
PRIMARY KEY (PlayerID, TeamID);