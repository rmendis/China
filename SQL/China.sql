-- China
-- Author: blkbutterrfly74
-- DateCreated: 1/31/2023 2:47:06 PM
--------------------------------------------------------------
Update Maps SET GridWidth = 26, GridHeight = 20 WHERE MapSizeType = 'MAPSIZE_DUEL';
Update Maps SET GridWidth = 36, GridHeight = 26 WHERE MapSizeType = 'MAPSIZE_TINY';
Update Maps SET GridWidth = 44, GridHeight = 32 WHERE MapSizeType = 'MAPSIZE_SMALL';
Update Maps SET GridWidth = 52, GridHeight = 36 WHERE MapSizeType = 'MAPSIZE_STANDARD';
Update Maps SET GridWidth = 60, GridHeight = 42 WHERE MapSizeType = 'MAPSIZE_LARGE';
Update Maps SET GridWidth = 72, GridHeight = 50 WHERE MapSizeType = 'MAPSIZE_HUGE';