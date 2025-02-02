setreadonly(string,false)
function string.split(str, seperator)
       if seperator == nil then
               seperator = "%s"
       end
       local t = {}
       for portion in string.gmatch(str, "([^"..seperator.."]+)") do
               table.insert(t, portion)
       end
       return t
end
function string.table(str)
   local string_table = {}
  for i=1,#str do
      table.insert(string_table,str:sub(i,i))
  end
 return string_table
end
setreadonly(string,true)

local function parse_line(line)
   local split_line = line:table()
   local name = ''
   local data = ''
   local data_switch = false
   for _,character in ipairs(split_line) do
       if character == '=' and data_switch == false then
           data_switch = true
           continue
       end
       if data_switch == false then
           name = name..character
       elseif data_switch == true then
           data = data..character
       end
   end
   data=tonumber(data) or data
   if data == '' then data = nil end
   return name,data
end
local function format_line(key,data)
   if type(key) == 'number' then
       return tostring(data)
   end
   local s = ("%s=%s"):format(tostring(key),tostring(data))
   return s
end

local raw_write_read = {
   fread = function(fname)
       local data = {
           array={};
       }
       if not isfile(fname) then return data end
       local raw_data = readfile(fname)
       local split_data = raw_data:split("\n")

       for iterator,line in ipairs(split_data) do
          local name,ldata = parse_line(line)
          if name == '' or name == '\n' or name == '\r' then continue end
          if not ldata then
          table.insert(data['array'],name)
          else
           data[name] = ldata    
           end
       end
       return data
   end;
   fwrite = function(fname,tdata)
       local raw_data = ''
       for i,data_pair in pairs(tdata) do
           if type(i) == 'number' or i=='array' then continue end
           raw_data = raw_data..format_line(i,data_pair)..'\n'
       end
       for i,single_data in ipairs(tdata.array) do
           raw_data = raw_data..format_line(i,single_data)..'\n'
       end
       print(raw_data)
       writefile(fname,raw_data)
   end;
}
if not isfolder("bot_data_transfer") then makefolder("bot_data_transfer") end
if not isfolder("bot_data_transfer/mailbox") then makefolder('bot_data_transfer/mailbox') end
local info = {
   ledger_name = "bot_data_transfer/ledger.bdata";
   mailbox_folder = "bot_data_transfer/mailboxes/";
   bot_id = game.Players.LocalPlayer.Name;
}
info['personal_mailbox'] = info.mailbox_folder..info.bot_id
info['data_list_name'] = info['personal_mailbox']..'/signals.bdata'


local function get_ledger()
  return raw_write_read.fread(info.ledger_name)['array']
end

local function send_data_signal(recipient,signal_name,data)
   if recipient == "All" then
   	for i,player_name in ipairs(get_ledger()) do
   		send_data_signal(player_name,signal_name,data)
   	end
   	  return true
   end
   local signal_data = data
   signal_data.array = signal_data.array or {}
   local sending_address = info.mailbox_folder..recipient
   if not isfolder(sending_address) then
      error("no signal folder found")
   end
   print(signal_data)
   raw_write_read.fwrite(sending_address..'/'..signal_name..'.signal',signal_data)
   local recipient_signal_ledger = info.mailbox_folder..recipient..'/signals.bdata'
   local signal_list = raw_write_read.fread(recipient_signal_ledger)
   table.insert(signal_list.array,signal_name)
   raw_write_read.fwrite(recipient_signal_ledger,signal_list)
end


local rs = game:GetService("RunService").RenderStepped
local local_player = game.Players.LocalPlayer

local function get_player(shortcut)
	if not shortcut then return nil end
  local player = nil
  local g = game.Players:GetPlayers()
  for i = 1, #g do
    if string.lower(string.sub(g[i].Name, 1, string.len(shortcut))) == string.lower(shortcut) then
      player = g[i]
      break
    end
  end
  return player
end

local function make_bots_chat(message,player_name)
		message =  "Wag Bot: "..message
		local bots = get_ledger()
		for i,bot_name in ipairs(get_ledger()) do
				send_data_signal(bot_name,"chat",{message_data=message,player=player_name})
		end
end

local player_message_connections = {

}




local function chat_handler(speaker,msg)
    if msg:sub(1,3) == '/e ' then msg = msg:sub(4,-1) end
	local msg_data = msg:split(" ")
	local command = msg_data[1]
	print(command)
	local success_player,player = pcall(get_player,msg_data[2])
	if not success_player then player = nil end
	if command == "!tp" then
		if not player then return end
		if not player.Character then return end
		local ph = player.Character.Humanoid.RootPart.Position
		send_data_signal("All","teleport",{x=ph.X;y=ph.Y;z=ph.Z})
	elseif command == "!wt" then
		if not player then return end
		if not player.Character then return end
		local ph = player.Character.Humanoid.RootPart.Position
		send_data_signal("All","walkto",{x=ph.X;y=ph.Y;z=ph.Z})
	elseif command == '!follow' then
		send_data_signal("All","follow",{player_name=player.Name})
	elseif command == '!unfollow' then
		send_data_signal("All","follow",{})	
	elseif command == '!bodyguard' then
		if not player then return end																
		send_data_signal("All","bodyguard",{player_name=player.Name})
	elseif command == '!unbodyguard' then
		send_data_signal("All","bodyguard",{})
    elseif command == '!look' then
        if not player then return end
        send_data_signal("All","lookat",{player_name=player.Name})
    elseif command == '!unlook' then
        send_data_signal("All","lookat",{})

        
    elseif command == '!rj' then
        send_data_signal("All","joinserver",{server_id=game.JobId})


    elseif command == '!repeat' then
		if not player then return end
         send_data_signal("All","setrepeatstatus",{player_name=player.Name,status=true})
    elseif command == '!unrepeat' then
    	send_data_signal("All","setrepeatstatus",{player_name=player.Name,status=false})


    elseif command == '!orbit' then
        if not player then return end
        send_data_signal("All","orbit",{player_name=player.Name})
    elseif command == '!unorbit' then
        send_data_signal("All","orbit",{})
	    elseif command == '!spam' then
        send_data_signal("All","spam",{})

    elseif command == '!forbit' then
        if not player then return end
        send_data_signal("All","forbit",{player_name=player.Name})
    elseif command == '!unforbit' then
        send_data_signal("All","forbit",{})


    elseif command == "!droptools" then
        send_data_signal("All","droptools",{})

    elseif command == "!dupetools" then
        if not player then return end
        local amount = tonumber(msg_data[3]) or 1
        local bot_count = #get_ledger()
        amount = math.floor((amount/bot_count)+1)
        send_data_signal("All","dupetools",{player_name=player.Name,amount=amount})


    elseif command == "!reset" then
        send_data_signal("All","reset",{})

    elseif command == "!lag" then
          send_data_signal("All","lag",{})
	elseif command == '!whitelist' and speaker == local_player then
		if not player then return end
		make_bots_chat(("%s has been whitelisted to use bot commands"):format(player.Name),player.Name)
		player_message_connections[player.Name] = player.Chatted:connect(function(msg)
			chat_handler(player,msg)
		end)
	elseif command and speaker == local_player then
		if not player then return end
		if player_message_connections[player.Name] then
			player_message_connections[player.Name]:Disconnect()
		end
	end
end

game.Players.LocalPlayer.Chatted:connect(function(message)
chat_handler(local_player,message)
end)
