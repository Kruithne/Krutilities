do
	-- [[ Addon Bootstrapping ]] --
	Krutilities = Krutilities or {};
	local _M = { Version = 1.8 };
	local _K = Krutilities;

	if _K[_M.Version] then
		-- This version has already been registered.
		return;
	end

	Krutilities[_M.Version] = _M;

	-- [[ Optimization ]] --
	local type = type;
	local pairs = pairs;
	local tan = tan; -- Not the same as math.tan.
	local floor = math.floor;
	local tableinsert = table.insert;
	local tableremove = table.remove;
	local CreateFrame = CreateFrame;
	local SetDesaturation = SetDesaturation;

	local TYPE_NUMBER = "number";
	local TYPE_TABLE = "table";

	-- [[ Global Request Function ]] --
	GetKrutilities = function(version)
		-- Provide requested version or throw error.
		if version then
			assert(Krutilities[version], "Krutilities: Version " .. version .. " requested but not loaded.");
			return Krutilities[version];
		end

		-- No version was provided, provide latest.
		local latestVersion = 0;
		local latestContainer = nil;

		for version, container in pairs(_K) do
			if latestVersion == 0 or version > latestVersion then
				latestVersion = version;
				latestContainer = container;
			end
		end

		return latestContainer;
	end

	-- [[ Local Functions ]] --
	local Shared_ProcessPoints = function(target, points, parent)
		if points then
			if type(points) == "string" then
				target:SetPoint(points, parent, points, 0, 0);
			else
				if #points == 0 then
					-- Single point.
					points.point = points.point or "CENTER";
					target:SetPoint(points.point, points.relativeTo or parent, points.relativePoint or points.point, points.x or 0, points.y or 0);
				else
					-- Many points
					for i = 1, #points do
						local point = points[i];
						point.point = point.point or "CENTER";
						target:SetPoint(point.point, point.relativeTo or parent, point.relativePoint or point.point, point.x or 0, point.y or 0);
					end
				end
			end
		end
	end

	local Shared_Sizing = function(target, node)
		local width = node.width or nil;
		local height = node.height or nil;

		if node.size then
			if type(node.size) == "table" then
				width = node.size[1];
				height = node.size[2];
			else
				width = node.size;
				height = node.size;
			end
		end

		if width then target:SetWidth(width); end
		if height then target:SetHeight(height); end
	end

	local Shared_Mixin = function(target, mixin)
		if mixin then
			for key, value in pairs(mixin) do
				target[key] = value;
			end
		end
	end

	local Shared_Inject = function(target, parent, injectSelf)
		if injectSelf then
			parent[injectSelf] = target;
		end
	end

	local Shared_DrawLayer = function(frame, node)
		if node.layer then
			frame:SetDrawLayer(node.layer, node.subLevel or 0);
		end
	end

	local Shared_CreateChild = function(createFunc, frame, node)
		local new = createFunc(frame, node);
		
		if node.buttonTex then
			if node.buttonTex == "PUSHED" then
				frame:SetPushedTexture(new);
			elseif node.buttonTex == "NORMAL" then
				frame:SetNormalTexture(new);
			elseif node.buttonTex == "HIGHLIGHT" then
				frame:SetHighlightTexture(new);
			end
		end

		if node.scrollChild then
			frame:SetScrollChild(new);
		end
	end

	local Shared_HandleChildren = function(frame, childFunc, node)
		if node == nil then
			return;
		end

		local nodeCount = #node;
		if nodeCount > 0 then
			-- Node contains children, spawn them all.
			for i = 1, nodeCount do
				Shared_CreateChild(childFunc, frame, node[i]);
			end
		else
			-- No children, treat as a single object.
			Shared_CreateChild(childFunc, frame, node);
		end
	end

	local ProcessColor = function(color, ...)
		if type(color) == "table" then
			if color.r then
				-- Color object.
				return color.r or 0, color.g or 0, color.b or 0, color.a or 1;
			else
				-- Generic Table.
				return color[1] or 0, color[2] or 0, color[3] or 0, color[4] or 1;
			end
		else
			-- Static values.
			local g, b, a = ...;
			return color or 0, g or 0, b or 0, a or 1;
		end
	end

	-- [[ Global Utility ]] --

	-- [[ Clone a table, shallow or deep ]] --
	_M.CloneTable = function(input, deep)
		local inputType = type(input);
		local output;

		if inputType == "table" then
			output = {};

			if deep then -- Deep copy (copy-by-value)
				for key, value in next, input, nil do
					output[_M.CloneTable(key, true)] = _M.CloneTable(value, true);
				end
			else -- Shallow copy (copy-by-reference)
				for key, value in pairs(input) do
					output[key] = value;
				end
			end
		else
			output = input;
		end

		return output;
	end

	-- [[ Dump an object using Blizzard's debugging tool ]] --
	_M.Dump = function(input, func)
		if type(input) ~= "string" then
			_K._TEMP = input;
			input = "Krutilities._TEMP";
		end
		SlashCmdList["DUMP"](input);
		_K._TEMP = nil;
	end

	-- [[ Event handler creation utility ]] --
	_M.EventHandler = function(addon, events)
		local eventFrame = CreateFrame("FRAME");
		local frameUpdateEvent = nil;

		for eventName, funcName in pairs(events) do
			if eventName == "FRAME_UPDATE" then
				-- Frame update event.
				frameUpdateEvent = funcName;
			else
				-- Normal events.
				eventFrame:RegisterEvent(eventName);
			end
		end

		-- Add normal event delegate function.
		eventFrame:SetScript("OnEvent", function(self, event, ...)
			addon[events[event]](addon, ...);
		end);

		if frameUpdateEvent then
			-- Add frame update delegate function.
			eventFrame:SetScript("OnUpdate", function(self, elapsed)
				addon[frameUpdateEvent](addon, elapsed);
			end);
		end

		return eventFrame;
	end

	-- [[ Command Handler Creation Utility ]] --
	_M.CommandHandler = function(addon, commands)
		for id, data in pairs(commands) do
			local prefix = "SLASH_" .. id;

			-- Command global assignments.
			for i = 1, #data.commands do
				_G[prefix .. i] = data.commands[i];
			end

			SlashCmdList[id] = addon[data.handler];
		end
	end

	--[[ Factory Functions ]]--
	local Factory_Generate = function(self)
		local dumpster = self._disposed;
		local frame = nil;

		if #dumpster > 0 then
			-- Disposed frame available, recycle it.
			frame = tableremove(dumpster, 1);
		else
			local data = self._data;
			
			-- If factory name is provided, generate incremented name.
			if data.factoryName then
				local index = self._index or 1;
				data.name = data.factoryName .. index;
				self._index = index + 1; -- Increase creation index.
			end

			frame = _M:Frame(self._data);
		end

		tableinsert(self._regions, frame);
		return frame;
	end

	local Factory_GetRegions = function(self)
		return self._regions;
	end

	local Factory_RecycleAll = function(self)
		local dumpster = self._disposed;
		local regions = self._regions;

		-- Copy all region references to dumpster.
		for i = 1, #regions do
			tableinsert(dumpster, regions[i]);
		end

		self._regions = {}; -- Reset region table.
	end

	local Factory_Recycle = function(self, region)
		-- Insert region reference into dumpster.
		tableinsert(self._disposed, region);

		local regionType = type(region);
		if regionType == TYPE_NUMBER then
			-- Index given for fast-track removal.
			tableremove(self._regions, region);
		elseif regionType == TYPE_TABLE then
			-- Attempt to find the specific region reference.
			local regions = self._regions;
			for i = 1, #regions do
				if regions[i] == region then
					tableremove(regions, i);
					return;
				end
			end
		end
	end

	_M.Factory = function(data)
		return {
			_data = data,
			_disposed = {},
			_regions = {},
			Generate = Factory_Generate,
			Recycle = Factory_Recycle,
			GetRegions = Factory_GetRegions,
			RecycleAll = Factory_RecycleAll
		};
	end

	--[[ UI Generation Functions ]]--
	_M.Frame = function(self, node)
		assert(type(node) == "table", "Krutilities:Frame called with invalid constructor table.");
		Shared_Mixin(node, node.mixin);

		local parent = node.parent;
		if self ~= _M then
			parent = self;
		end

		local name = node.name;
		if node.parentName then
			name = "$parent" .. node.parentName;
		end

		if parent then
			-- Parent cannot be string, attempt a global lookup.
			if type(parent) == "string" then
				parent = _G[parent];
			end
		else
			-- Default to UIParent.
			parent = UIParent;
		end

		local frame = CreateFrame(node.type or "FRAME", name, parent, node.inherit);

		if node.hidden then frame:Hide(); end
		if node.enableMouse then frame:EnableMouse(); end

		if node.strata then
			frame:SetFrameStrata(node.strata);
		end

		-- Generic stuff.
		Shared_Sizing(frame, node);
		Shared_Inject(frame, parent, node.injectSelf);

		-- Anchor points
		local points = node.points;
		if points == nil then
			points = { point = "CENTER" };
		end
		Shared_ProcessPoints(frame, points, parent);
		if node.setAllPoints then frame:SetAllPoints(true); end

		-- Backdrop
		if node.backdrop then frame:SetBackdrop(node.backdrop); end

		if node.backdropColor then
			local r, g, b, a = ProcessColor(node.backdropColor);
			frame:SetBackdropColor(r, g, b, a);
		end

		if node.backdropBorderColor then
			local r, g, b, a = ProcessColor(node.backdropBorderColor);
			frame:SetBackdropBorderColor(r, g, b, a);
		end

		-- Model
		if node.displayID then frame:SetDisplayInfo(node.displayID); end
		if node.animTargetDist then frame:SetTargetDistance(node.animTargetDist); end
		if node.animHeightFactor then frame:SetHeightFactor(node.animHeightFactor); end
		if node.facing then frame:SetFacing(node.facing); end
		if node.animation then frame:SetAnimation(node.animation); end

		-- Data
		if node.data then
			for key, value in pairs(node.data) do
				frame[key] = value;
			end
		end

		-- Editbox Stuff
		if node.type == "EDITBOX" then
			if node.multiLine then frame:SetMultiLine(true); else frame:SetMultiLine(false); end
			if node.autoFocus then frame:SetAutoFocus(true); else frame:SetAutoFocus(false); end
		end

		-- Children
		Shared_HandleChildren(frame, _M.Texture, node.textures);
		Shared_HandleChildren(frame, _M.Frame, node.frames);
		Shared_HandleChildren(frame, _M.Text, node.texts);

		-- Button stuff
		if node.type == "BUTTON" then
			if node.normalTexture then frame:SetNormalTexture(node.normalTexture); end
			if node.pushedTexture then frame:SetPushedTexture(node.pushedTexture); end
			if node.highlightTexture then frame:SetHighlightTexture(node.highlightTexture); end
		end

		-- Scripts
		if node.scripts then
			for scriptEvent, scriptFunc in pairs(node.scripts) do
				if scriptEvent == "OnLoad" then
					scriptFunc(frame);
				else
					frame:SetScript(scriptEvent, scriptFunc);

					if not node.hidden and scriptEvent == "OnShow" then
						scriptFunc(frame);
					end
				end
			end
		end

		-- Inject shortcut functions.
		frame.SpawnTexture = _M.Texture;
		frame.SpawnText = _M.Text;
		frame.SpawnFrame = _M.Frame;

		return frame;
	end

	_M.Texture = function(frame, node)
		assert(type(node) == "table", "Krutilities:Texture called with invalid constructor table.");
		Shared_Mixin(node, node.mixin);

		local parent = node.parent;
		if not parent then
			parent = frame ~= _M and frame or UIParent;
		end

		local name = node.name;
		if node.parentName then
			name = "$parent" .. node.parentName;
		end

		local tex = parent:CreateTexture(name, node.layer, node.inherit, node.subLevel or 0);

		-- Generic stuff
		Shared_Sizing(tex, node);
		Shared_Inject(tex, frame, node.injectSelf);
		Shared_DrawLayer(frame, node);

		-- Masking
		if node.mask then tex:SetMask(node.mask); end

		-- Tiling
		tex:SetTexture(node.texture, node.tile or node.tileX, node.tile or node.tileY);

		-- Texture blending
		if node.blendMode then
			tex:SetBlendMode(node.blendMode);
		end

		-- Anchor points
		local setAllPoints = node.setAllPoints;
		if node.points == nil and setAllPoints ~= false then
			setAllPoints = true;
		end
		
		Shared_ProcessPoints(tex, node.points, frame);
		if setAllPoints then tex:SetAllPoints(true); end

		-- Colour filter
		if node.color then
			local r, g, b, a = ProcessColor(node.color);
			tex:SetVertexColor(r, g, b, a);
		end

		-- Desaturation
		if node.desaturate then
			SetDesaturation(tex, 1);
		end

		-- Tex coords.
		if node.texCoord then
			tex:SetTexCoord(node.texCoord[1], node.texCoord[2], node.texCoord[3], node.texCoord[4]);
		end

		return tex;
	end

	_M.Text = function(frame, node)
		assert(type(node) == "table", "Krutilities:Text called with invalid constructor table.");
		Shared_Mixin(node, node.mixin);

		local parent = node.parent;
		if not parent then
			parent = frame ~= _M and frame or UIParent;
		end

		local name = node.name;
		if node.parentName then
			name = "$parent" .. node.parentName;
		end

		local text = frame:CreateFontString(name, node.layer, node.inherit);

		-- Generic Stuff
		Shared_Sizing(text, node);
		Shared_Inject(text, frame, node.injectSelf);
		Shared_DrawLayer(frame, node);

		-- Text / Alignment
		if node.text then text:SetText(node.text); end
		if node.justifyH then text:SetJustifyH(node.justifyH); end
		if node.justifyV then text:SetJustifyV(node.justifyV); end
		if node.maxLines then text:SetMaxLines(node.maxLines); end

		-- Colouring
		if node.color then
			local r, g, b, a = ProcessColor(node.color);
			text:SetTextColor(r, g, b, a);
		end

		-- Anchor points
		if node.points == nil then node.points = { point = "CENTER" }; end
		Shared_ProcessPoints(text, node.points, frame);

		return text;
	end

	-- [[ Circular Progress ]] --
	-- [[ Based on code/concepts by Semlar and Infus ]] --
	local defaultTexCoord = { ULx = 0, ULy = 0, LLx = 0, LLy = 1, URx = 1, URy = 0, LRx = 1, LRy = 1 };
	local pointOrder = { "LL", "UL", "UR", "LR", "LL", "UL", "UR", "LR", "LL", "UL", "UR", "LR" };

	local exactAngles = {
		{0.5, 0},  -- 0°
		{1, 0},    -- 45°
		{1, 0.5},  -- 90°
		{1, 1},    -- 135°
		{0.5, 1},  -- 180°
		{0, 1},    -- 225°
		{0, 0.5},  -- 270°
		{0, 0}     -- 315°
	};

	local angleToCoord = function(angle)
		angle = angle % 360;

		if angle % 45 == 0 then
			local index = floor(angle / 45) + 1;
			return exactAngles[index][1], exactAngles[index][2];
		end

		if (angle < 45) then
			return 0.5 + tan(angle) / 2, 0;
		elseif (angle < 135) then
			return 1, 0.5 + tan(angle - 90) / 2 ;
		elseif (angle < 225) then
			return 0.5 - tan(angle) / 2, 1;
		elseif (angle < 315) then
			return 0, 0.5 - tan(angle - 90) / 2;
		elseif (angle < 360) then
			return 0.5 + tan(angle) / 2, 0;
		end
	end

	local CircularTexture_Coord_SetAngle = function(self, angle1, angle2)
		--TestFrame:SetProgress(0, 30)

		local index = floor((angle1 + 45) / 90); -- 0

		local middleCorner = pointOrder[index + 1];
	    local startCorner = pointOrder[index + 2];
	    local endCorner1 = pointOrder[index + 3];
	    local endCorner2 = pointOrder[index + 4];

	    self:MoveCorner(middleCorner, 0.5, 0.5);
	    self:MoveCorner(startCorner, angleToCoord(angle1));

	    local edge1 = floor((angle1 - 45) / 90);
	    local edge2 = floor((angle2 - 45) / 90);

	    if edge1 == edge2 then
	      self:MoveCorner(endCorner1, angleToCoord(angle2));
	    else
	      self:MoveCorner(endCorner1, defaultTexCoord[endCorner1 .. "x"], defaultTexCoord[endCorner1 .. "y"]);
	    end

	    self:MoveCorner(endCorner2, angleToCoord(angle2));
	end

	local CircularTexture_Coord_MoveCorner = function(self, corner, x, y)
		local width, height = self.texture:GetSize();
		local rx = defaultTexCoord[corner .. "x"] - x;
		local ry = defaultTexCoord[corner .. "y"] - y;

		self[corner .. "vx"] = -rx * width;
		self[corner .. "vy"] = ry * height;
		self[corner .. "x"] = x;
		self[corner .. "y"] = y;
	end

	local CircularTexture_Coord_Apply = function(self)
		local texture = self.texture;
		texture:SetVertexOffset(UPPER_RIGHT_VERTEX, self.URvx, self.URvy);
		texture:SetVertexOffset(UPPER_LEFT_VERTEX, self.ULvx, self.ULvy);
		texture:SetVertexOffset(LOWER_RIGHT_VERTEX, self.LRvx, self.LRvy);
		texture:SetVertexOffset(LOWER_LEFT_VERTEX, self.LLvx, self.LLvy);

		texture:SetTexCoord(self.ULx, self.ULy, self.LLx, self.LLy, self.URx, self.URy, self.LRx, self.LRy);
	end

	local CircularTexture_Coord_SetFull = function(self)
	    self.ULx = 0;
		self.ULy = 0;
		self.LLx = 0;
		self.LLy = 1;
		self.URx = 1;
		self.URy = 0;
		self.LRx = 1;
		self.LRy = 1;

		self.ULvx = 0;
		self.ULvy = 0;
		self.LLvx = 0;
		self.LLvy = 0;
		self.URvx = 0;
		self.URvy = 0;
		self.LRvx = 0;
		self.LRvy = 0;
	end

	local CircularTexture_Show = function(self)
		self:Apply();
		self.texture:Show();
	end

	local CircularTexture_Hide = function(self)
		self.texture:Hide();
	end

	local CircularTexture_CreateCoord = function(texture)
		return {
			ULx = 0, ULy = 0, LLx = 0, LLy = 1, URx = 1, URy = 0, LRx = 1, LRy = 1,
		    ULvx = 0, ULvy = 0, LLvx = 0, LLvy = 0, URvx = 0, URvy = 0, LRvx = 0, LRvy = 0,

		    texture = texture,

		    -- Helper functions
		    Show = CircularTexture_Show,
		    Hide = CircularTexture_Hide,
		    Apply = CircularTexture_Coord_Apply,
		    SetFull = CircularTexture_Coord_SetFull,
		    SetAngle = CircularTexture_Coord_SetAngle,
		    MoveCorner = CircularTexture_Coord_MoveCorner,
		};
	end

	local CircularTexture_SetProgress = function(self, angle1, angle2)
		local coords = self._coords;

		-- Full progress, show the full texture.
		if angle2 - angle1 >= 360 then
			coords[1]:SetFull();
			coords[1]:Show();

			coords[2]:Hide();
			coords[3]:Hide();
			return;
		end

		-- No angle difference, show nothing.
		if angle1 == angle2 then
			for i = 1, 3 do
				coords[i]:Hide();
			end
			return;
		end

		local index1 = floor((angle1 + 45) / 90); -- 0
		local index2 = floor((angle2 + 45) / 90); -- 0

		if index1 + 1 >= index2 then
			coords[1]:SetAngle(angle1, angle2);
			coords[1]:Show();

			coords[2]:Hide();
			coords[3]:Hide();
		elseif index1 + 3 >= index2 then
			local firstEndAngle = (index1 + 1) * 90 + 45;
			coords[1]:SetAngle(angle1, firstEndAngle);
			coords[1]:Show();

			coords[2]:SetAngle(firstEndAngle, angle2);
			coords[2]:Show();

			coords[3]:Hide();
		else
			local firstEndAngle = (index1 + 1) * 90 + 45;
			local secondEndAngle = firstEndAngle + 180;

			coords[1]:SetAngle(angle1, firstEndAngle);
			coords[1]:Show();

			coords[2]:SetAngle(firstEndAngle, secondEndAngle);
			coords[2]:Show();

			coords[3]:SetAngle(secondEndAngle, angle2);
			coords[3]:Show();
		end
	end

	_M.CircularTexture = function(self, frameData, textureData)
		local frame = self:Frame(frameData);
		frame._textures = {};
		frame._coords = {};
		frame.SetProgress = CircularTexture_SetProgress;

		for i = 1, 3 do
			local texture = frame:SpawnTexture(textureData);
			frame._textures[i] = texture;
			frame._coords[i] = CircularTexture_CreateCoord(texture);
		end

		return frame;
	end
end