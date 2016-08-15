local VERSION = 1.0;

if Krutilities == nil or Krutilities.Version < VERSION then
	Krutilities = {};
	local K = Krutilities;

	-- [[ Clone a table, shallow or deep. ]] --
	K.CloneTable = function(input, deep)
		local inputType = type(input);
		local output;

		if inputType == "table" then
			output = {};

			if deep then
				-- Deep copy.
				for key, value in next, input, nil do
					output[K.CloneTable(key, true)] = K.CloneTable(value, true);
				end
			else
				-- Shallow copy.
				for key, value in pairs(input) do
					output[key] = value;
				end
			end
		else
			output = input;
		end

		return output;
	end

	K.Dump = function(input)
		if type(input) ~= "string" then
			K._TEMP = input;
			input = "Krutilities._TEMP";
		end
		SlashCmdList["DUMP"](input);
	end

	local Shared_ProcessPoints = function(target, points, parent)
		if points then
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

	local Shared_Sizing = function(target, node)
		local width = node.width or 0;
		local height = node.height or 0;

		if node.size then
			if type(node.size) == "table" then
				width = node.size[1];
				height = node.size[2];
			else
				width = node.size;
				height = node.size;
			end
		end

		target:SetSize(width, height);
	end

	local Shared_Inject = function(target, parent, injectSelf)
		if injectSelf then
			parent[injectSelf] = target;
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
				childFunc(frame, node[i]);
			end
		else
			-- No children, treat as a single object.
			childFunc(frame, node);
		end
	end

	K.Frame = function(self, node)
		if self ~= Krutilities then
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

		-- Generic stuff.
		Shared_Sizing(frame, node);
		Shared_Inject(frame, node.parent, node.injectSelf);

		-- Anchor points
		if node.points == nil then node.points = {}; end
		if #node.points == 0 then node.points.point = "CENTER"; end
		Shared_ProcessPoints(frame, node.points, node.parent);
		if node.setAllPoints then frame:SetAllPoints(true); end

		-- Scripts
		if node.scripts then
			for scriptEvent, scriptFunc in pairs(node.scripts) do
				frame:SetScript(scriptEvent, scriptFunc);
			end
		end

		-- Children
		Shared_HandleChildren(frame, K.Texture, node.textures);
		Shared_HandleChildren(frame, K.Frame, node.frames);
		Shared_HandleChildren(frame, K.Text, node.texts);

		-- Inject shortcut functions.
		frame.SpawnTexture = K.Texture;
		frame.SpawnText = K.Text;
		frame.SpawnFrame = K.Frame;
		return frame;
	end

	K.Texture = function(frame, node)
		if node.parentName then node.name = "$parent" .. node.parentName; end
		local tex = frame:CreateTexture(node.name, node.layer, node.inherit, node.subLevel or 0);

		-- Generic stuff
		Shared_Sizing(tex, node);
		Shared_Inject(tex, frame, node.injectSelf);

		-- Tiling
		local tileX = node.tile or node.tileX;
		local tileY = node.tile or node.tileY;

		tex:SetHorizTile(tileX);
		tex:SetVertTile(tileY);
		tex:SetTexture(node.texture, tileX, tileY);

		-- Anchor points
		if node.points == nil or #node.points == 0 then
			node.setAllPoints = true;
		end
		Shared_ProcessPoints(tex, node.points, frame);
		if node.setAllPoints then tex:SetAllPoints(true); end

		-- Colour filter
		if node.color then
			local r = node.color.r or node.color[1] or 0;
			local g = node.color.g or node.color[2] or 0;
			local b = node.color.b or node.color[3] or 0;
			local a = node.color.a or node.color[4] or 1;

			tex:SetVertexColor(r, g, b, a);
		end

		-- Tex coords.
		if node.texCoord then
			tex:SetTexCoord(node.texCoord[1], node.texCoord[2], node.texCoord[3], node.texCoord[4]);
		end

		return tex;
	end

	K.Text = function(frame, node)
		if node.parentName then node.name = "$parent" .. node.parentName; end
		local text = frame:CreateFontString(node.name, node.layer, node.inherit);

		-- Generic Stuff
		Shared_Sizing(text, node);
		Shared_Inject(text, frame, node.injectSelf);

		-- Text / Alignment
		if node.text then text:SetText(node.text); end
		if node.justifyH then text:SetJustifyH(node.justifyH); end
		if node.justifyV then text:SetJustifyV(node.justifyV); end

		-- Colouring
		if node.color then
			local r = node.color.r or node.color[1] or 0;
			local g = node.color.g or node.color[2] or 0;
			local b = node.color.b or node.color[3] or 0;
			local a = node.color.a or node.color[4] or 1;

			text:SetTextColor(r, g, b, a);
		end

		-- Anchor points
		if node.points == nil then node.points = {}; end
		if #node.points == 0 then node.points.point = "CENTER"; end
		Shared_ProcessPoints(text, node.points, frame);

		return text;
	end
end