local data = minetest.get_mod_storage()
local forms = {"chat", "me", "join"}
local guiRow = 1 -- Which row in the GUI is selected
local default = "#FFFFFF" -- Default colour

for i = 1,3 do -- Make sure all our defaults are in place.
	local key = "default_" .. forms[i]
	if not data:to_table().fields[key] then data:set_string(key, default) end
end

local chatSource = function(msg) -- Find the source of the message
	if string.sub(msg, 1, 1) == "<" then -- Normal chat messages
		local parts = string.split(msg, ">") -- Split it at the closing >
		return {form = "chat", name = string.sub(parts[1], 2)} -- Return the first part excluding the first character
	elseif string.sub(msg, 1, 2) == "* " then -- /me messages
		local parts = string.split(msg, " ") -- Split the message before and after the name
		return {form = "me", name = parts[2]}
	elseif string.sub(msg, 1, 4) == "*** " then -- Join/leave messages
		local parts = string.split(msg, " ") -- Split the message before and after the name
		return {form = "join", name = parts[2]}
	end
	return false -- If nothing else returned, return false
end

local setColor = function(key, value)
	if key == nil or key == "" then -- Reject bad input
		minetest.display_chat_message("Invalid setting name.")
		return
	end
	if string.len(key) > 8 and string.sub(key, 1, 8) == "default_" then -- Default settings
		if value == nil then -- Can't delete defaults
			minetest.display_chat_message("Cannot delete defaults!")
			return
		end
	else -- Player settings
		key = "player_" .. key -- Regular players
		minetest.display_chat_message("Color set sucessfully! (" .. key .. ")")
	end
	data:set_string(key, value)
end

local getList = function(readable) -- Return nicely sorted array of colour defenitions (if readable is true, results will be human-readable.)
	local list = data:to_table().fields
	local arr = {}
	for key,value in pairs(list) do -- Get key and value for all pairs
		if string.sub(key, 1, 7) == "player_" then -- Exclude defaults
			if readable then key = string.sub(key, 8) end -- Isolate the player name
			arr[#arr+1] = key .. "," .. value
		end
	end
	table.sort(arr) -- Sort alphabetically.
	for i = 1,3 do -- List defaults at end
		local key = "default_" .. forms[i] -- default value prefix + default type
		local value = list[key] -- Get colour
		arr[#arr+1] = key .. "," .. value
	end
	return arr -- Numerical index table in key,value format. Must be numerical index for sorting.
end

local getFormspec = function(modify, defaultText)
	if not modify then
		local tableDef = ""
		local list = getList(true)
		for i = 1,#list do -- Convert to formspec-friendly format
			local item = string.split(list[i], ",")
			tableDef = tableDef .. item[1] .. ",".. item[2] .. "," .. item[2] .. ","
		end
		tableDef = string.sub(tableDef, 1, string.len(tableDef)-1)
		return [[
			size[8,9, false]
			label[1,0.5;Techy5's Colored Chat]
			button[1,1;2,1;main_modify;Modify...]
			button[3,1;2,1;main_delete;Delete]
			button[5,1;2,1;main_add;Add...]
			tablecolumns[text;color;text]
			table[1,2;6,6;main_table;]] .. tableDef .. [[;1]
			button_exit[1,8;2,1;exit;Exit]
			tooltip[main_modify;Change the color for the selected element]
			tooltip[main_delete;Delete the selected element]
			tooltip[main_add;Add a color definition]
		]]
	else
		return [[size[8,3, false]
			field[1.3,1.3;2,1;mod_player;Player;]] .. defaultText .. [[]
			field[3.3,1.3;2,1;mod_color;HTML/hex color;]
			button[5,1;2,1;mod_set;Set]
			button[1,2;2,1;mod_back;<- Back]
		]]
	end
end

minetest.register_chatcommand("setcolor", { -- Assign a colour to chat messages from a specific person
	params = "<name> <color>",
	description = "Colourize a specified player's chat messages",
	func = function(param)
		local args = string.split(param, " ") -- Split up the arguments
		setColor(args[1], args[2])
	end
})

minetest.register_chatcommand("delcolor", {
	params = "<name>",
	description = "Set a specified player's chat messages to the default color",
	func = function(param)
		setColor(param, nil)
	end
})

minetest.register_chatcommand("listcolors", {
	params = "",
	description = "List player/color pairs",
	func = function(param)
		local list = getList(true)
		for i = 1,#list do -- Print list to chat
			local item = string.split(list[i], ",")
			minetest.display_chat_message(item[1] .. ", ".. minetest.colorize(item[2], item[2]))
		end
	end
})

minetest.register_chatcommand("gui", {
	params = "",
	description = "Display colored chat GUI",
	func = function(param)
		minetest.show_formspec("chatcolor:maingui", getFormspec())
	end
})

minetest.register_on_formspec_input(function(formname, fields)
	if not string.find(formname, "chatcolor") then return end -- Avoid conflicts
	if fields.main_table then guiRow = tonumber(string.match(fields.main_table, "%d+")) end -- Get the selected table row on change.
	
	if fields.main_delete then
		local list = getList(true)
		local key = string.split(list[guiRow], ",")[1]
		setColor(key, nil)
		minetest.show_formspec("chatcolor:maingui", getFormspec())
	elseif fields.main_modify then
		local list = getList(true)
		local key = string.split(list[guiRow], ",")[1]
		minetest.show_formspec("chatcolor:modify", getFormspec(true, key))
	elseif fields.main_add then
		minetest.show_formspec("chatcolor:modify", getFormspec(true, ""))
	elseif fields.mod_set and fields.mod_player and fields.mod_color then
		setColor(fields.mod_player, fields.mod_color)
		minetest.show_formspec("chatcolor:maingui", getFormspec())
	elseif fields.mod_back then
		minetest.show_formspec("chatcolor:maingui", getFormspec())
	end
end)

minetest.register_on_connect(function()
	minetest.register_on_receiving_chat_messages(function(message)
		local msgPlain = minetest.strip_colors(message)
		local source = chatSource(msgPlain)
		
		if source then -- Normal chat/me/join messages
			local key = "player_" .. source.name -- The setting name
			local color = data:get_string(key) -- Get the desired colour
			if color == "" then -- If no colour, set to default
				color = data:get_string("default_" .. source.form)
			end
			message = minetest.colorize(color, msgPlain)
			minetest.display_chat_message(message)
			return true -- Override the original chat
		elseif string.sub(msgPlain, 1, 2) == "# " then -- /status message
			local list = data:to_table().fields
			for key,value in pairs(list) do -- Get key and value for all pairs
				if string.sub(key, 1, 7) == "player_" then -- Exclude default settings
					key = string.sub(key, 8) -- Isolate the player name
					msgPlain = string.gsub(msgPlain, key, minetest.colorize(value, key)) -- Replace plain name with coloured version
				end
			end
			minetest.display_chat_message(msgPlain)
			return true -- Override the original chat
		end
	end)
end)
