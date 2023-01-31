-------------------------------------------------------------------------------
--	FILE:	 China.lua
--	AUTHORS:  Bob Thomas (Sirian), blkbutterfly74
--	PURPOSE: Regional map script - Chinese Heartland
-------------------------------------------------------------------------------
--	Copyright (c) 2013 Firaxis Games, Inc. All rights reserved.
-------------------------------------------------------------------------------

include "MapEnums"
include "MapUtilities"
include "MountainsCliffs"
include "RiversLakes"
include "FeatureGenerator"
include "TerrainGenerator"
include "NaturalWonderGenerator"
include "ResourceGenerator"
include "AssignStartingPlots"

local g_iW, g_iH;

-------------------------------------------------------------------------------
function GenerateMap()
	print("Generating China Map");
	local pPlot;

	-- Set globals
	g_iW, g_iH = Map.GetGridSize();
	g_iFlags = TerrainBuilder.GetFractalFlags();
	local temperature = MapConfiguration.GetValue("temperature"); -- Default setting is Temperate.
	if temperature == 4 then
		temperature  =  1 + TerrainBuilder.GetRandomNumber(3, "Random Temperature- Lua");
	end
	
	plotTypes = GeneratePlotTypes();
	terrainTypes = GenerateTerrainTypes(plotTypes, g_iW, g_iH, g_iFlags, false, temperature);

	for i = 0, (g_iW * g_iH) - 1, 1 do
		pPlot = Map.GetPlotByIndex(i);
		if (plotTypes[i] == g_PLOT_TYPE_HILLS) then
			terrainTypes[i] = terrainTypes[i] + 1;
		end
		TerrainBuilder.SetTerrainType(pPlot, terrainTypes[i]);
	end
	
	-- Temp
	AreaBuilder.Recalculate();
	local biggest_area = Areas.FindBiggestArea(false);
	print("After Adding Hills: ", biggest_area:GetPlotCount());

	-- River generation is affected by plot types, originating from highlands and preferring to traverse lowlands.
	AddRivers();
	
	-- Lakes would interfere with rivers, causing them to stop and not reach the ocean, if placed any sooner.
	local numLargeLakes = GameInfo.Maps[Map.GetMapSize()].Continents
	AddLakes(numLargeLakes);

	AddFeatures();
	
	print("Adding cliffs");
	AddCliffs(plotTypes, terrainTypes);

	local args = {
		numberToPlace = GameInfo.Maps[Map.GetMapSize()].NumNaturalWonders,
	};
	local nwGen = NaturalWonderGenerator.Create(args);

	AreaBuilder.Recalculate();
	TerrainBuilder.AnalyzeChokepoints();
	TerrainBuilder.StampContinents();
	
	--for i = 0, (g_iW * g_iH) - 1, 1 do
		--pPlot = Map.GetPlotByIndex(i);
		--print ("i: plotType, terrainType, featureType: " .. tostring(i) .. ": " .. tostring(plotTypes[i]) .. ", " .. tostring(terrainTypes[i]) .. ", " .. tostring(pPlot:GetFeatureType(i)));
	--end
	local resourcesConfig = MapConfiguration.GetValue("resources");
	local startconfig = MapConfiguration.GetValue("start"); -- Get the start config
	local args = {
		iWaterLux = 2,
		resources = resourcesConfig,
		START_CONFIG = startConfig,
	};
	local resGen = ResourceGenerator.Create(args);

	print("Creating start plot database.");
	
	-- START_MIN_Y and START_MAX_Y is the percent of the map ignored for major civs' starting positions.
	local args = {
		MIN_MAJOR_CIV_FERTILITY = 175,
		MIN_MINOR_CIV_FERTILITY = 50, 
		MIN_BARBARIAN_FERTILITY = 1,
		START_MIN_Y = 15,
		START_MAX_Y = 15,
		START_CONFIG = startconfig,
	};
	local start_plot_database = AssignStartingPlots.Create(args)

	local GoodyGen = AddGoodies(g_iW, g_iH);
end


------------------------------------------------------------------------------
function GetMapInitData(MapSize)
	-- China has fully custom grid sizes to match the slice of Earth being represented.
	local Width = GameInfo.Maps[MapSize].GridWidth;
	local Height = GameInfo.Maps[MapSize].GridHeight;
	local WrapX = false;
	return {Width = Width, Height = Height, WrapX = WrapX,}
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- China uses custom plot generation with regional specificity.
------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Setting Plot Types (Lua China) ...");
	local iW, iH = Map.GetGridSize();
	-- Initiate plot table, fill all data slots with type PLOT_LAND
	local plotTypes = {};
	table.fill(plotTypes, g_PLOT_TYPE_LAND, iW * iH);

	-- Grains for reducing "clumping" of hills/peaks.
	local grain_amount = GameInfo.Maps[Map.GetMapSize()].PlateValue;

	local hillsFrac = Fractal.Create(iW, iH, grain_amount, {}, 7, 6);
	local peaksFrac = Fractal.Create(iW, iH, grain_amount + 1, {}, 7, 6);
	local regionsFrac = Fractal.Create(iW, iH, grain_amount, {}, 7, 6);

	local iHillsBottom1 = hillsFrac:GetHeight(20);
	local iHillsTop1 = hillsFrac:GetHeight(30);
	local iHillsBottom2 = hillsFrac:GetHeight(70);
	local iHillsTop2 = hillsFrac:GetHeight(80);
	local iForty = hillsFrac:GetHeight(40);
	local iFifty = hillsFrac:GetHeight(50);
	local iSixty = hillsFrac:GetHeight(60);
	local iPeakTibet = peaksFrac:GetHeight(87);
	local iPeakNW = peaksFrac:GetHeight(95);
	local iPeakSichuan = peaksFrac:GetHeight(97);
	local iHillsRegional = hillsFrac:GetHeight(94);

	-- Define the Pacific.
	print("Simulate the Pacific Ocean. (Lua China) ...");
	local pacific_coords = {
		{math.floor(iW * 0.56), 0},
		{math.floor(iW * 0.52), math.floor(iH * 0.08)},
		{math.floor(iW - 1), math.floor(iH * 0.9)},
	};
	-- Draw the Pacific Line and fill in everything east of it with ocean.
	for loop = 1, 2 do
		local startX = pacific_coords[loop][1];
		local startY = pacific_coords[loop][2];
		local endX = pacific_coords[loop + 1][1];
		local endY = pacific_coords[loop + 1][2];
		local dx = endX - startX;
		local dy = endY - startY
		local slope = 0;
		if dy ~= 0 then
			slope = dx / dy;
		end
		local x = startX;
		for y = startY, endY - 1 do
			x = x + slope;
			local iX = math.floor(x);
			for loop_x = iX, iW - 1 do
				local i = y * iW + loop_x + 1;
				plotTypes[i] = g_PLOT_TYPE_OCEAN;
			end
		end
	end
	
	-- Define the Indian, which will be in the SW corner.
	local indian_coords = {
		{0, math.floor(iH * 0.16)},
		{math.floor(iW * 0.08), math.floor(iH * 0.2)},
		{math.floor(iW * 0.16), 0},
	};
	-- Draw the Indian Line and fill in everything south of it with ocean.
	for loop = 1, 2 do
		local startX = indian_coords[loop][1];
		local startY = indian_coords[loop][2];
		local endX = indian_coords[loop + 1][1];
		local endY = indian_coords[loop + 1][2];
		local dx = endX - startX;
		local dy = endY - startY
		local slope = 0;
		if dx ~= 0 then
			slope = dy / dx;
		end
		local y = startY;
		for x = startX, endX - 1 do
			y = y + slope;
			local iY = math.floor(y);
			for loop_y = 0, iY do
				local i = loop_y * iW + x + 1;
				plotTypes[i] = g_PLOT_TYPE_OCEAN;
				print("c", i);
			end
		end
	end

-- Add the mainland bulge as an oval of land plots.
	local centerX = iW * 0.64;
	local centerY = iH * 0.52;
	local majorAxis = iW * 0.32;
	local minorAxis = iH * 0.37;
	local majorAxisSquared = majorAxis * majorAxis;
	local minorAxisSquared = minorAxis * minorAxis;
	for x = 0, iW - 1 do
		for y = 0, iH - 1 do
			local deltaX = x - centerX;
			local deltaY = y - centerY;
			local deltaXSquared = deltaX * deltaX;
			local deltaYSquared = deltaY * deltaY;
			local d = deltaXSquared/majorAxisSquared + deltaYSquared/minorAxisSquared;
			if d <= 1 then
				if y <= iH - 1 then
					local i = y * iW + x + 1;
					plotTypes[i] = g_PLOT_TYPE_LAND;
				end
			end
		end
	end

	-- Define the hilly regions and append their plots to their plot lists. GLOBAL variables used here.
	himalayas = {};
	sichuan = {};
	desert = {};
	tibetan_plateau = {};
	central_china = {};
	south_china = {};
	arid_northwest = {};
	grasslands = {};
	for x  = 0, iW - 1 do
		for y = 0, iH - 1 do
			local i = y * iW + x + 1;
			if x <= iW * 0.15 and y >= iH * 0.4 and y <= iH * 0.47 then
				table.insert(himalayas, i);
			elseif x >= iW * 0.225 and x <= iW * 0.44 and y >= iH * 0.32 and y <= iH * 0.61 then
				table.insert(sichuan, i);
			elseif x <= iW * 0.26 and y >= iH * 0.83 then
				table.insert(desert, i);
			elseif x >= iW * 0.54 and x <= iW * 0.65 and y >= iH * 0.5 and y <= iH * 0.72 then
				table.insert(central_china, i);
			elseif x <= iW * 0.72 and y >= iH * 0.81 then
				table.insert(arid_northwest, i);
			elseif x <= iW * 0.4 and y >= iH * 0.45 then
				table.insert(tibetan_plateau, i);
			elseif x >= iW * 0.35 and y <= iH * 0.45 then
				table.insert(south_china, i);
			elseif x >= iW * 0.4 and y >= iH * 0.4 then
				table.insert(grasslands, i);
			end
        end
	end

	-- Now assign plot types. Note, the plot table is already filled with flatlands.
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local i = y * iW + x + 1;
			-- Regional membership checked, effects chosen.
			-- Python had a simpler, less verbose method for checking table membership.
			local inHima = false;
			local inSichuan = false;
			local inDesert = false;
			local inCent = false;
			local inArid = false;
			local inTibet = false;
			local inSouth = false;
			local inGrass = false;
			for memberPlot, plotIndex in ipairs(himalayas) do
				if i == plotIndex then
					inHima = true;
					break
				end
			end
			for memberPlot, plotIndex in ipairs(sichuan) do
				if i == plotIndex then
					inSichuan = true;
					break
				end
			end
			for memberPlot, plotIndex in ipairs(desert) do
				if i == plotIndex then
					inDesert = true;
					break
				end
			end
			for memberPlot, plotIndex in ipairs(central_china) do
				if i == plotIndex then
					inCent = true;
					break
				end
			end
			for memberPlot, plotIndex in ipairs(arid_northwest) do
				if i == plotIndex then
					inArid = true;
					break
				end
			end
			for memberPlot, plotIndex in ipairs(tibetan_plateau) do
				if i == plotIndex then
					inTibet= true;
					break
				end
			end
			for memberPlot, plotIndex in ipairs(south_china) do
				if i == plotIndex then
					inSouth = true;
					break
				end
			end
			for memberPlot, plotIndex in ipairs(grasslands) do
				if i == plotIndex then
					inGrass = true;
					break
				end
			end
			local hillVal = hillsFrac:GetHeight(x,y);
			if inHima then
				plotTypes[i] = g_PLOT_TYPE_MOUNTAIN;
			elseif inSichuan then
				if hillVal >= iSixty then
					local peakVal = peaksFrac:GetHeight(x,y);
					if (peakVal >= iPeakSichuan) then
						plotTypes[i] = g_PLOT_TYPE_MOUNTAIN;
					else
						plotTypes[i] = g_PLOT_TYPE_HILLS;
					end
				end
			elseif inDesert then
				if hillVal >= iHillsTop2 then
					local peakVal = peaksFrac:GetHeight(x,y);
					if (peakVal >= iPeakNW) then
						plotTypes[i] = g_PLOT_TYPE_MOUNTAIN;
					else
						plotTypes[i] = g_PLOT_TYPE_HILLS;
					end
				end
			elseif inCent then
				if ((hillVal >= iHillsBottom1 and hillVal <= iForty) or (hillVal >= iSixty and hillVal <= iHillsTop2)) then
					plotTypes[i] = g_PLOT_TYPE_HILLS;
				end
			elseif inArid then
				if hillVal >= iSixty then
					local peakVal = peaksFrac:GetHeight(x,y);
					if (peakVal >= iPeakNW) then
						plotTypes[i] = g_PLOT_TYPE_MOUNTAIN;
					else
						plotTypes[i] = g_PLOT_TYPE_HILLS;
					end
				end
			elseif inTibet then
				if hillVal >= iForty then
					local peakVal = peaksFrac:GetHeight(x,y);
					if (peakVal >= iPeakTibet) then
						plotTypes[i] = g_PLOT_TYPE_MOUNTAIN;
					else
						plotTypes[i] = g_PLOT_TYPE_HILLS;
					end
				end
			elseif inSouth then
				if plotTypes[i] ~= g_PLOT_TYPE_OCEAN then
					if ((hillVal >= iHillsBottom1 and hillVal <= iHillsTop1) or (hillVal >= iHillsBottom2 and hillVal <= iHillsTop2)) then
						plotTypes[i] = g_PLOT_TYPE_HILLS;
					end
				end
			elseif inGrass then
				if plotTypes[i] ~= g_PLOT_TYPE_OCEAN then
					if ((hillVal >= iHillsBottom1 and hillVal <= iHillsTop1)) then
						plotTypes[i] = g_PLOT_TYPE_HILLS;
					end
				end
			else
				if plotTypes[i] ~= g_PLOT_TYPE_OCEAN then
					if hillVal >= iHillsRegional then
						plotTypes[i] = g_PLOT_TYPE_HILLS;
					end
				end
			end
		end
	end

	return plotTypes;
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- China uses a custom terrain generation.
------------------------------------------------------------------------------
function GenerateTerrain()
	print("Generating Terrain (Lua China) ...");
	local iW, iH = Map.GetGridSize();
	local terrainTypes = {};
	local terrainDesert	= g_TERRAIN_TYPE_DESERT;
	local terrainPlains	= g_TERRAIN_TYPE_PLAINS;
	local terrainGrass	= g_TERRAIN_TYPE_GRASS;	

	-- Initiate terrain table, fill all land slots with type TERRAIN_GRASS
	table.fill(terrainTypes, terrainGrass, iW * iH);
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local plot = Map.GetPlot(x, y)
			if plot:IsWater() then
				local i = y * iW + x; -- C++ Plot indices, starting at 0.
				terrainTypes[i] = plot:GetTerrainType();
			end
		end
	end

	-- Set up fractals and thresholds
	local plains_check = Fractal.Create(iW, iH, 5, {}, 6, 6);
	local desert_check = Fractal.Create(iW, iH, 4, {}, 6, 6);
	local iHunan = plains_check:GetHeight(65)
	local iDesert = desert_check:GetHeight(30)
	local iDesertPlains = plains_check:GetHeight(15)
	local iTibet = plains_check:GetHeight(25)
	local iNW = plains_check:GetHeight(35)

	-- Main loop
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local i = y * iW + x + 1;
			local plot = Map.GetPlot(x, y)
			if plot:IsWater() then
				terrainTypes[i - 1] = plot:GetTerrainType();
			else
				local plainsVal = plains_check:GetHeight(x,y);
				local inSichuan = false;
				local inDesert = false;
				local inArid = false;
				local inTibet = false;
				for memberPlot, plotIndex in ipairs(sichuan) do
					if i == plotIndex then
						inSichuan = true;
						break
					end
				end
				for memberPlot, plotIndex in ipairs(desert) do
					if i == plotIndex then
						inDesert = true;
						break
					end
				end
				for memberPlot, plotIndex in ipairs(arid_northwest) do
					if i == plotIndex then
						inArid = true;
						break
					end
				end
				for memberPlot, plotIndex in ipairs(tibetan_plateau) do
					if i == plotIndex then
						inTibet= true;
						break
					end
				end
				if inSichuan then
					if plainsVal >= iHunan then
						terrainTypes[i - 1] = terrainPlains;
					end
				elseif inDesert then
					if plainsVal >= iDesertPlains then
						local desertVal = desert_check:GetHeight(x,y);
						if desertVal >= iDesert then
							terrainTypes[i - 1] = terrainDesert;
						else
							terrainTypes[i - 1] = terrainPlains;
						end
					end
				elseif inArid then
					if plainsVal >= iNW then
						terrainTypes[i - 1] = terrainPlains;
					end
				elseif inTibet then
					if plainsVal >= iTibet then
						terrainTypes[i - 1] = terrainPlains;
					end
				elseif x >= iW * 0.57 and x <= iW * 0.75 and y >= iH * 0.31 and y<= iH * 0.47 then
					if plainsVal >= iHunan then
						terrainTypes[i - 1] = terrainPlains;
					end
				end
			end
		end
	end

	return terrainTypes;
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function GetRiverValueAtPlot(plot)

    -- Prevent running back into the sea
	if (plot:IsCoastalLand()) then
		return 1000;
	end

	if(plot:IsNWOfCliff() or plot:IsWOfCliff() or plot:IsNEOfCliff()) then
		return 1000;
	elseif(plot:IsNaturalWonder() or AdjacentToNaturalWonder(plot)) then
		return 1000;
	end

	local sum = GetPlotElevation(plot) * 20;

	local numDirections = DirectionTypes.NUM_DIRECTION_TYPES;
	for direction = 0, numDirections - 1, 1 do

		local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), direction);

		if (adjacentPlot ~= nil) then
			sum = sum + GetPlotElevation(adjacentPlot);	
		else
			sum = 1000;  -- Prevent running off the map
		end
		
	end

	sum = sum + TerrainBuilder.GetRandomNumber(10, "River Rand");

	return sum;
end

------------------------------------------------------------------------------
function DoRiver(startPlot, thisFlowDirection, originalFlowDirection, riverID)
	-- Customizing to handle problems in top row of the map. Only this aspect has been altered.

	local iW, iH = Map.GetGridSize()
	thisFlowDirection = thisFlowDirection or FlowDirectionTypes.NO_FLOWDIRECTION;
	originalFlowDirection = originalFlowDirection or FlowDirectionTypes.NO_FLOWDIRECTION;

	-- pStartPlot = the plot at whose SE corner the river is starting
	if (riverID == nil) then
		riverID = nextRiverID;
		nextRiverID = nextRiverID + 1;
	end

	local otherRiverID = _rivers[startPlot]
	if (otherRiverID ~= nil and otherRiverID ~= riverID and originalFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then
		return; -- Another river already exists here; can't branch off of an existing river!
	end

	local riverPlot;
	
	local bestFlowDirection = FlowDirectionTypes.NO_FLOWDIRECTION;
	if (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTH) then
	
		riverPlot = startPlot;
		local adjacentPlot = Map.GetAdjacentPlot(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_EAST);
		if ( adjacentPlot == nil or riverPlot:IsWOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater() ) then
			return;
		end

		_rivers[riverPlot] = riverID;
		TerrainBuilder.SetWOfRiver(riverPlot, true, thisFlowDirection);
		riverPlot = Map.GetAdjacentPlot(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_NORTHEAST);
		
	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHEAST) then
	
		riverPlot = startPlot;
		local adjacentPlot = Map.GetAdjacentPlot(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHEAST);
		if ( adjacentPlot == nil or riverPlot:IsNWOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater() ) then
			return;
		end

		_rivers[riverPlot] = riverID;
		TerrainBuilder.SetNWOfRiver(riverPlot, true, thisFlowDirection);    
		-- riverPlot does not change
	
	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST) then
	
		riverPlot = Map.GetAdjacentPlot(startPlot:GetX(), startPlot:GetY(), DirectionTypes.DIRECTION_EAST);
		if (riverPlot == nil) then
			return;
		end
		
		local adjacentPlot = Map.GetAdjacentPlot(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHWEST);
		if (adjacentPlot == nil or riverPlot:IsNEOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater()) then
			return;
		end

		_rivers[riverPlot] = riverID;
		TerrainBuilder.SetNEOfRiver(riverPlot, true, thisFlowDirection);	    
		-- riverPlot does not change
	
	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTH) then
	
		riverPlot = Map.GetAdjacentPlot(startPlot:GetX(), startPlot:GetY(), DirectionTypes.DIRECTION_SOUTHWEST);
		if (riverPlot == nil) then
			return;
		end
		
		local adjacentPlot = Map.GetAdjacentPlot(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_EAST);
		if (adjacentPlot == nil or riverPlot:IsWOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater()) then
			return;
		end
		
		_rivers[riverPlot] = riverID;
		TerrainBuilder.SetWOfRiver(riverPlot, true, thisFlowDirection);
		-- riverPlot does not change
	
	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST) then

		riverPlot = startPlot;
		local adjacentPlot = Map.GetAdjacentPlot(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHEAST);
		if (adjacentPlot == nil or riverPlot:IsNWOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater()) then
			return;
		end
		
		_rivers[riverPlot] = riverID;
		TerrainBuilder.SetNWOfRiver(riverPlot, true, thisFlowDirection);	    
		-- riverPlot does not change

	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHWEST) then
		
		riverPlot = startPlot;
		local adjacentPlot = Map.GetAdjacentPlot(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHWEST);
		
		if ( adjacentPlot == nil or riverPlot:IsNEOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater()) then
			return;
		end

		_rivers[riverPlot] = riverID;
		TerrainBuilder.SetNEOfRiver(riverPlot, true, thisFlowDirection);	    
		riverPlot = Map.GetAdjacentPlot(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_WEST);

	else
		-- River is starting here, set the direction in the next step
		riverPlot = startPlot;		
	end

	if (riverPlot == nil or riverPlot:IsWater()) then
		-- The river has flowed off the edge of the map or into the ocean. All is well.
		return; 
	end

	-- Storing X,Y positions as locals to prevent redundant function calls.
	local riverPlotX = riverPlot:GetX();
	local riverPlotY = riverPlot:GetY();
	
	-- Table of methods used to determine the adjacent plot.
	local adjacentPlotFunctions = {
		[FlowDirectionTypes.FLOWDIRECTION_NORTH] = function() 
			return Map.GetAdjacentPlot(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_NORTHWEST); 
		end,
		
		[FlowDirectionTypes.FLOWDIRECTION_NORTHEAST] = function() 
			return Map.GetAdjacentPlot(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_NORTHEAST);
		end,
		
		[FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST] = function() 
			return Map.GetAdjacentPlot(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_EAST);
		end,
		
		[FlowDirectionTypes.FLOWDIRECTION_SOUTH] = function() 
			return Map.GetAdjacentPlot(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_SOUTHWEST);
		end,
		
		[FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST] = function() 
			return Map.GetAdjacentPlot(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_WEST);
		end,
		
		[FlowDirectionTypes.FLOWDIRECTION_NORTHWEST] = function() 
			return Map.GetAdjacentPlot(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_NORTHWEST);
		end	
	}
	
	if(bestFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then

		-- Attempt to calculate the best flow direction.
		local bestValue = math.huge;
		for flowDirection, getAdjacentPlot in pairs(adjacentPlotFunctions) do
			
			if (GetOppositeFlowDirection(flowDirection) ~= originalFlowDirection) then
				
				if (thisFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION or
					flowDirection == TurnRightFlowDirections[thisFlowDirection] or 
					flowDirection == TurnLeftFlowDirections[thisFlowDirection]) then
				
					local adjacentPlot = getAdjacentPlot();
					
					if (adjacentPlot ~= nil) then
					
						local value = GetRiverValueAtPlot(adjacentPlot);
						if (flowDirection == originalFlowDirection) then
							value = (value * 3) / 4;
						end
						
						if (value < bestValue) then
							bestValue = value;
							bestFlowDirection = flowDirection;
						end

					-- Custom addition for Highlands, to fix river problems in top row of the map. Any other all-land map may need similar special casing.
					elseif adjacentPlot == nil and riverPlotY == iH - 1 then -- Top row of map, needs special handling
						if flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTH or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHWEST or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHEAST then
							
							local value = TerrainBuilder.GetRandomNumber(5, "River Rand");
							if (flowDirection == originalFlowDirection) then
								value = (value * 3) / 4;
							end
							if (value < bestValue) then
								bestValue = value;
								bestFlowDirection = flowDirection;
							end
						end

					-- Custom addition for Highlands, to fix river problems in left column of the map. Any other all-land map may need similar special casing.
					elseif adjacentPlot == nil and riverPlotX == 0 then -- Left column of map, needs special handling
						if flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTH or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTH or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHWEST or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST then
							
							local value = TerrainBuilder.GetRandomNumber(5, "River Rand");
							if (flowDirection == originalFlowDirection) then
								value = (value * 3) / 4;
							end
							if (value < bestValue) then
								bestValue = value;
								bestFlowDirection = flowDirection;
							end
						end
					end
				end
			end
		end
		
		-- Try a second pass allowing the river to "flow backwards".
		if(bestFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then
		
			local bestValue = math.huge;
			for flowDirection, getAdjacentPlot in pairs(adjacentPlotFunctions) do
			
				if (thisFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION or
					flowDirection == TurnRightFlowDirections[thisFlowDirection] or 
					flowDirection == TurnLeftFlowDirections[thisFlowDirection]) then
				
					local adjacentPlot = getAdjacentPlot();
					
					if (adjacentPlot ~= nil) then
						
						local value = GetRiverValueAtPlot(adjacentPlot);
						if (value < bestValue) then
							bestValue = value;
							bestFlowDirection = flowDirection;
						end
					end	
				end
			end
		end
	end
	
	--Recursively generate river.
	if (bestFlowDirection ~= FlowDirectionTypes.NO_FLOWDIRECTION) then
		if  (originalFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then
			originalFlowDirection = bestFlowDirection;
		end
		
		DoRiver(riverPlot, bestFlowDirection, originalFlowDirection, riverID);
	end
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- China uses a custom feature generation.
------------------------------------------------------------------------------
function FeatureGenerator:GetLatitudeAtPlot(iX, iY)
	local lat = 0.45 * (iY / self.iGridH);
	return lat
end
------------------------------------------------------------------------------
function FeatureGenerator:AddIceAtPlot(plot, iX, iY, lat)
	return
end

------------------------------------------------------------------------------
function AddFeatures()
	print("Adding Features (Lua China) ...");

	local args = {rainfall = 2}
	local featuregen = FeatureGenerator.Create(args);

	featuregen:AddFeatures();
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function AssignStartingPlots:CanPlaceCityStateAt(x, y, area_ID, force_it, ignore_collisions)
	-- Overriding default city state placement to prevent city states from being placed too close to map edges.
	local iW, iH = Map.GetGridSize();
	local plot = Map.GetPlot(x, y)
	local area = plot:GetArea()
	
	-- Adding this check for China
	if x < 1 or x >= iW - 1 or y < 1 or y >= iH - 1 then
		return false
	end
	--
	
	if area ~= area_ID and area_ID ~= -1 then
		return false
	end
	local plotType = plot:GetPlotType()
	if plotType == g_PLOT_TYPE_OCEAN or plotType == g_PLOT_TYPE_MOUNTAIN then
		return false
	end
	local terrainType = plot:GetTerrainType()
	if terrainType == TerrainTypes.g_TERRAIN_TYPE_SNOW then
		return false
	end
	local plotIndex = y * iW + x + 1;
	if self.cityStateData[plotIndex] > 0 and force_it == false then
		return false
	end
	local plotIndex = y * iW + x + 1;
	if self.playerCollisionData[plotIndex] == true and ignore_collisions == false then
		return false
	end
	return true
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function StartPlotSystem()
	print("Creating start plot database.");
	local start_plot_database = AssignStartingPlots.Create()
	
	print("Dividing the map in to Regions.");
	-- Regional Division Method 1: Biggest Landmass
	local args = {
		method = 1,
		};
	start_plot_database:GenerateRegions(args)

	print("Choosing start locations for civilizations.");
	start_plot_database:ChooseLocations()
	
	print("Normalizing start locations and assigning them to Players.");
	start_plot_database:BalanceAndAssign()

	print("No Natural Wonders available on this script.");
	--start_plot_database:PlaceNaturalWonders()

	print("Placing Resources and City States.");
	start_plot_database:PlaceResourcesAndCityStates()
end
------------------------------------------------------------------------------