BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "Stages" (
	"Id"	INTEGER NOT NULL UNIQUE,
	"name"	VARCHAR(20) DEFAULT 'New Fitness stage',
	"displayName"	TEXT,
	"femBsXml"	TEXT,
	"femBsUrl"	TEXT,
	"manBsXml"	TEXT,
	"manBsUrl"	TEXT,
	"excludedRaces"	TEXT DEFAULT 'Child',
	"muscleDefType"	INTEGER DEFAULT 0,
	"muscleDefLvl"	INTEGER DEFAULT 0,
	PRIMARY KEY("Id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "MuscleDefTypes" (
	"Id"	INTEGER NOT NULL UNIQUE,
	"name"	VARCHAR(20),
	PRIMARY KEY("Id" AUTOINCREMENT)
);
INSERT INTO "Stages" VALUES (1,'Default',NULL,NULL,NULL,NULL,NULL,'Child',0,0);
INSERT INTO "MuscleDefTypes" VALUES (1,'Plain');
INSERT INTO "MuscleDefTypes" VALUES (2,'Athletic');
INSERT INTO "MuscleDefTypes" VALUES (3,'Fat');
COMMIT;
