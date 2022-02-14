-- random-geek's colored chat CSM

local guiRow = 1 -- Which row in the GUI is selected

local data = minetest.get_mod_storage()
local MESSAGE_TYPES = {"chat", "me", "join"}
local DEFAULT_COLOR = "#FFFFFF"

-- Make sure all our defaults are in place.
for _, type in ipairs(MESSAGE_TYPES) do
	local key = "default_" .. type
	if data:get_string(key) == "" then
		data:set_string(key, DEFAULT_COLOR)
	end
end

-- Find the type and source of a chat message.
local function message_info(msg)
	if string.sub(msg, 1, 1) == "<" then -- Normal chat messages (<player> message)
		local parts = string.split(msg, ">")
		return {type = "chat", name = string.sub(parts[1], 2)}
	elseif string.sub(msg, 1, 2) == "* " then -- /me messages (* player message)
		local parts = string.split(msg, " ")
		return {type = "me", name = parts[2]}
	elseif string.sub(msg, 1, 4) == "*** " then -- Join/leave messages (*** player joined/left the game.)
		local parts = string.split(msg, " ")
		return {type = "join", name = parts[2]}
	else -- Unrecognized message type
		return nil
	end
end

-- Set player/default color.
-- name: player name or default_whatever
-- color: HTML string, hex color ('#' will be prepended if necessary), or nil to delete entry.
local function set_color(name, color)
	if not name or name == "" then
		minetest.display_chat_message("Player or setting name required.")
		return
	elseif not string.match(name, "^[%a%d-_]+$") then
		minetest.display_chat_message(string.format("Invalid player or setting name '%s'.", name))
		return
	elseif color == "" then
		minetest.display_chat_message("Color (hex color or color name) required.")
		return
	end

	local key
	if string.sub(name, 1, 8) == "default_" then
		if not color then
			minetest.display_chat_message("Cannot delete defaults!")
			return
		end
		key = name
	else
		-- Note: Commands/GUI omit the player prefix.
		key = "player_" .. name
	end

	-- Check color if it exists.
	if color then
		-- Prepend '#' to hex colors if necessary.
		local newColor = color
		if tonumber(newColor, 16) then
			newColor = "#" .. newColor
		end

		if not minetest.colorspec_to_colorstring(newColor) then
			minetest.display_chat_message(string.format("Invalid color name '%s'.", color))
			return
		end

		data:set_string(key, newColor)
		minetest.display_chat_message(
			string.format("Set color for %s to %s.", name, minetest.colorize(newColor, newColor))
		)
	else -- Delete player color entry
		data:set_string(key, "")
		minetest.display_chat_message(string.format("Deleted color for %s.", name))
	end
end

-- Return a nicely sorted array of {name, color} pairs.
local function get_list()
	local list = data:to_table().fields
	local arr = {}

	-- List players, excluding player_ prefix.
	for key, color in pairs(list) do
		if string.sub(key, 1, 7) == "player_" then
			local name = string.sub(key, 8)
			arr[#arr + 1] = {name, color}
		end
	end

	-- Sort alphabetically.
	table.sort(
		arr,
		function(a, b)
			return a[1] < b[1]
		end
	)

	-- List defaults at end
	for _, type in ipairs(MESSAGE_TYPES) do
		local key = "default_" .. type
		local color = list[key]
		arr[#arr + 1] = {key, color}
	end

	return arr
end

local function get_formspec(modify, defaultPlayer, defaultColor)
	if not modify then -- Fetch main screen
		local list = get_list()

		-- Convert list to formspec-friendly format
		local tableRows = {}
		for _, row in ipairs(list) do
			tableRows[#tableRows + 1] = row[1] .. "," .. row[2] .. "," .. row[2]
		end
		local tableString = table.concat(tableRows, ",")

		return [[
			formspec_version[5]
			size[8,9]
			label[0.5,0.6;Colored Chat]
			button[0.5,1;2.1,0.8;main_modify;Modify...]
			button[2.9,1;2.2,0.8;main_delete;Delete]
			button[5.4,1;2.1,0.8;main_add;Add...]
			tablecolumns[text;color;text]
			table[0.5,2.1;7,5.3;main_table;]] .. tableString .. [[;]] .. guiRow .. [[]
			button_exit[0.5,7.7;2.1,0.8;exit;Exit]
			tooltip[main_modify;Change the color for the selected element]
			tooltip[main_delete;Delete the selected element]
			tooltip[main_add;Add a color definition]
		]]
	else -- Fetch modify screen
		return [[
			formspec_version[5]
			size[8,3.2]
			field[0.5,0.8;3.4,0.8;mod_player;Player;]] .. defaultPlayer .. [[]
			field[4.1,0.8;3.4,0.8;mod_color;HTML/hex color;]] .. defaultColor .. [[]
			button[5,1.9;2.5,0.8;mod_set;Set]
			button[0.5,1.9;2.5,0.8;mod_cancel;Cancel]
		]]
	end
end

minetest.register_on_formspec_input(function(formname, fields)
	-- Ignore potential formspecs from other mods.
	if string.sub(formname, 1, 10) ~= "chatcolor:" then
		return
	end

	-- Update the selected row index if needed.
	if fields.main_table then
		local event = minetest.explode_table_event(fields.main_table)
		if event.type == "CHG" or event.type == "DCL" then
			guiRow = event.row
		end
	end

	if fields.main_delete then
		local list = get_list()
		local key = list[guiRow][1]
		set_color(key, nil)
		minetest.show_formspec("chatcolor:maingui", get_formspec())
	elseif fields.main_modify then
		local row = get_list()[guiRow]
		-- Get formspec and send selected name to modify screen
		minetest.show_formspec("chatcolor:modify", get_formspec(true, row[1], row[2]))
	elseif fields.main_add then
		minetest.show_formspec("chatcolor:modify", get_formspec(true, "", ""))
	elseif fields.mod_set and fields.mod_player and fields.mod_color then
		set_color(fields.mod_player, fields.mod_color)
		minetest.show_formspec("chatcolor:maingui", get_formspec())
	elseif fields.mod_cancel then
		minetest.show_formspec("chatcolor:maingui", get_formspec())
	end
end)

minetest.register_chatcommand("colors", {
	params = "",
	description = "Display colored chat GUI.",
	func = function(param)
		guiRow = 1 -- Select first row of table
		minetest.show_formspec("chatcolor:maingui", get_formspec())
	end
})

minetest.register_chatcommand("setcolor", { -- Assign a color to chat messages from a specific person
	params = "<name> <color>",
	description = "Colorize a specified player's chat messages.",
	func = function(param)
		local args = string.split(param, " ")
		-- If color is empty, pass an empty string to avoid deleting the entry.
		set_color(args[1], args[2] or "")
	end
})

minetest.register_chatcommand("delcolor", {
	params = "<name>",
	description = "Set a specified player's chat messages to the default color.",
	func = function(param)
		set_color(param, nil)
	end
})

minetest.register_chatcommand("listcolors", {
	params = "",
	description = "List player/color pairs.",
	func = function(param)
		local list = get_list()
		for _, row in ipairs(list) do
			minetest.display_chat_message(row[1] .. ", " .. minetest.colorize(row[2], row[2]))
		end
	end
})

-- I don't remember if or why `register_on_mods_loaded` was necessary.
minetest.register_on_mods_loaded(function()
	minetest.register_on_receiving_chat_message(function(message)
		local plain = minetest.strip_colors(message)
		local info = message_info(plain)

		if info then -- Normal chat/me/join messages
			local color = data:get_string("player_" .. info.name)
			if color == "" then -- If no color, set to default
				color = data:get_string("default_" .. info.type)
			end

			local colorized = minetest.colorize(color, plain)
			minetest.display_chat_message(colorized)
			return true -- Override the original chat
		elseif string.sub(plain, 1, 2) == "# " then -- /status message
			local colorized = plain

			local list = data:to_table().fields
			for key, color in pairs(list) do
				if string.sub(key, 1, 7) == "player_" then
					local playerName = string.sub(key, 8)
					-- Replace plain name with colored version
					colorized = string.gsub(colorized, playerName, minetest.colorize(color, playerName))
				end
			end

			minetest.display_chat_message(colorized)
			return true -- Override the original chat
		end
	end)
end)
