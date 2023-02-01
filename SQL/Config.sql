-- Config
-- Author: blkbutterfly74
-- DateCreated: 2/1/2023 2:42:27 AM
--------------------------------------------------------------

INSERT INTO Maps (File, Domain, Name, Description)
VALUES 
	('{FEB3116E-EE24-4DDA-9837-C7C2FC3008B2}Maps/Script_Random_China.lua', 'StandardMaps', 'LOC_MAP_CHINA_NAME', 'LOC_MAP_CHINA_DESCRIPTION');

INSERT INTO Parameters (Key1, Key2, ParameterId, Name, Description, Domain, DefaultValue, ConfigurationGroup, ConfigurationId, GroupId, SortIndex)
VALUES
	-- rainfall
	('Map', '{FEB3116E-EE24-4DDA-9837-C7C2FC3008B2}Maps/Script_Random_China.lua', 'Rainfall', 'LOC_MAP_RAINFALL_NAME', 'LOC_MAP_RAINFALL_DESCRIPTION', 'Rainfall', 2, 'Map', 'rainfall', 'MapOptions', 250),

	-- world age
	('Map', '{FEB3116E-EE24-4DDA-9837-C7C2FC3008B2}Maps/Script_Random_China.lua', 'WorldAge', 'LOC_MAP_WORLD_AGE_NAME', 'LOC_MAP_WORLD_AGE_DESCRIPTION', 'WorldAge', 2, 'Map', 'world_age', 'MapOptions', 230);