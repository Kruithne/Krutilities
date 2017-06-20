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
	local CreateFrame = CreateFrame;

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
	_M.Dump = function(input)
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

		for eventName, funcName in pairs(events) do
			eventFrame:RegisterEvent(eventName);
		end

		eventFrame:SetScript("OnEvent", function(self, event, ...)
			addon[events[event]](addon, ...);
		end);

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

	_M.Frame = function(self, node)
		assert(type(node) == "table", "Krutilities:Frame called with invalid constructor table.");
		Shared_Mixin(node, node.mixin);

		if self ~= _M then
			node.parent = self;
		end

		if node.parentName then node.name = "$parent" .. node.parentName; end
		if node.parent then
			-- Parent cannot be string, attempt a global lookup.
			if type(node.parent) == "string" then
				node.parent = _G[node.parent];
			end
		else
			-- Default to UIParent.
			node.parent = UIParent;
		end

		local frame = CreateFrame(node.type or "FRAME", node.name, node.parent, node.inherit);

		if node.hidden then frame:Hide(); end
		if node.enableMouse then frame:EnableMouse(); end

		if node.strata then
			frame:SetFrameStrata(node.strata);
		end

		-- Generic stuff.
		Shared_Sizing(frame, node);
		Shared_Inject(frame, node.parent, node.injectSelf);

		-- Anchor points
		if node.points == nil then node.points = { point = "CENTER" }; end
		Shared_ProcessPoints(frame, node.points, node.parent);
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

		if not node.parent then
			node.parent = frame ~= _M and frame or UIParent;
		end

		if node.parentName then node.name = "$parent" .. node.parentName; end
		local tex = node.parent:CreateTexture(node.name, node.layer, node.inherit, node.subLevel or 0);

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
		if node.points == nil and node.setAllPoints ~= false then
			node.setAllPoints = true;
		end
		
		Shared_ProcessPoints(tex, node.points, frame);
		if node.setAllPoints then tex:SetAllPoints(true); end

		-- Colour filter
		if node.color then
			local r, g, b, a = ProcessColor(node.color);
			tex:SetVertexColor(r, g, b, a);
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

		if not node.parent then
			node.parent = frame ~= _M and frame or UIParent;
		end

		if node.parentName then node.name = "$parent" .. node.parentName; end
		local text = frame:CreateFontString(node.name, node.layer, node.inherit);

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
end