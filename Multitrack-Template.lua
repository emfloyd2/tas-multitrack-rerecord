--[[
Multi-track re-record script template.

This template was created from DarkKobold's Multitrack LUA script created
for TAS of TMNT Arcade and The Simpsons Arcade.

The intent of this template script is to make multiplayer TAS'ing more
approachable to newbies - empowering them to quickly create a
multi-track re-recording rig for the game they plan to TAS
--]]

-- Max number of lines to display in LUA overlay
MAX_DISPLAY_LINES = 5;

-- local NameTable = {'Player 1', 'Player 2', 'None', 'All'};
local NameTable = {'Player 1', 'Player 2'};
local visualtbl = {'^','v','<','>','O','O','O'}
local tabinp = {'up','down','left','right','Z','X','C','9','0'};

-- Dictionary holding Key Value Pairs
-- for input labels
-- Key is derived from I don't know what yet
local i = {};
for n=(PLAYER_COUNT-1),0,-1 do
	i[1+n*INPUT_BUTTON_COUNT] = "P"..(n+1).." Up";
	i[2+n*INPUT_BUTTON_COUNT] = "P"..(n+1).." Down";
	i[3+n*INPUT_BUTTON_COUNT] = "P"..(n+1).." Left";
	i[4+n*INPUT_BUTTON_COUNT] = "P"..(n+1).." Right";
	i[5+n*INPUT_BUTTON_COUNT] = "P"..(n+1).." Button 1";
	i[6+n*INPUT_BUTTON_COUNT] = "P"..(n+1).." Button 2";
	i[7+n*INPUT_BUTTON_COUNT] = "P"..(n+1).." Button 3";
	i[8+n*INPUT_BUTTON_COUNT] = "P"..(n+1).." Start";
	i[9+n*INPUT_BUTTON_COUNT] = "P"..(n+1).." Coin";
end

-- Max number of players
PLAYER_COUNT = table.getn(NameTable);

-- Total number of buttons being drawn in UI
MONITORED_BUTTON_COUNT = table.getn(visualtbl);

-- Table representing all the input buttons for your game
INPUT_BUTTON_COUNT = table.getn(tabinp);

current_pressed_keys, last_pressed_keys = {}, {};
AllFrames = {};

local inp ={};
local StartFrame = emu.framecount();
local RecFrames = 0;

-- This is the character whose inputs are currently being recorded
-- Toggling between characters is controlled by the test function - which looks
-- at a special set of keys set aside to switch control between the playable
-- characters
character_being_recorded = 3;

-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))
    else
      print(formatting .. v)
    end
  end
end

--*****************************************************************************
function press(button)
--*****************************************************************************
-- Checks if a button is pressed.
-- The tables it accesses should be obvious in the next line.

    if current_pressed_keys[button] and not last_pressed_keys[button] then
        return true

    end
    return false
end

function test()
	current_pressed_keys = input.get();
	--print(current_pressed_keys);
	RF = {};
	if current_pressed_keys['pageup'] then
		character_being_recorded = 1;
	elseif current_pressed_keys['pagedown'] then
		character_being_recorded = 2;
	elseif current_pressed_keys['numpad3'] then
		character_being_recorded = 3;
	elseif current_pressed_keys['numpad4'] then
		character_being_recorded = 4;
	end;

  --print(movie.mode());
	if movie.mode() ~= 'playback' then
  --print('WE ARE HERE');
		-- Loop through characters
		for n = (PLAYER_COUNT-1),0,-1 do
			--print("CURRENT CHARACTER "..(character_being_recorded).. "=="..(n+1));
			if character_being_recorded == n+1 or character_being_recorded == 4 then
				m = 0;
				-- Loop through buttons for each character
				for j = INPUT_BUTTON_COUNT,1,-1 do
					--print("Testing Player "..(n+1).." Button "..(tabinp[j]));
					m = m * 2;
					-- if button for this character is currently pressed
					if current_pressed_keys[tabinp[j]] then
						-- Input for this character's button is marked as true
							--print(tabinp[j].." ".."PRESSED!");
							inp[i[j+n*INPUT_BUTTON_COUNT]] = true;
						m = m+1;
					else
							--print(tabinp[j].." ".."NONE");
	   					inp[i[j+n*INPUT_BUTTON_COUNT]] = false;
	   				end;
	   			end;
				RF[n+1] = m;
			else
				if (emu.framecount()-StartFrame) >= RecFrames then
					for j = INPUT_BUTTON_COUNT,1,-1 do
						inp[i[j+n*INPUT_BUTTON_COUNT]] = false;
					end;
					RF[n+1] = 0;
				else
					TF = AllFrames[emu.framecount()-StartFrame+1];
					control = TF[n+1];
					for j = 1,INPUT_BUTTON_COUNT,1 do
						if math.mod(control,2) == 1 then
							inp[i[j+n*INPUT_BUTTON_COUNT]] = true;
						else
							inp[i[j+n*INPUT_BUTTON_COUNT]] = false;
						end;
						control = math.floor(control/2);
					end;
					RF[n+1] = TF[n+1];
				end;
			end;
		end;
	AllFrames[emu.framecount()-StartFrame+1] = RF;
	end;
	--tprint(inp, 4);
	joypad.set(inp);
	RecFrames = math.max(RecFrames, emu.framecount()-StartFrame);
	gui.text(1,1,'Recording: ' .. NameTable[character_being_recorded]);
	last_pressed_keys = current_pressed_keys;
end;


function afterframe()
	inpm = joypad.get();
	if movie.mode() == 'playback' then
		RF = {};
		for n = (PLAYER_COUNT-1),0,-1 do
			m = 0;
			for j = INPUT_BUTTON_COUNT,1,-1 do
				if inpm[i[j+n*INPUT_BUTTON_COUNT]] then
				z = 1 else z = 0; end;
				m = m*2;
				m = m + z;
			end;
			RF[n+1] = m;
		end;
		AllFrames[emu.framecount()-StartFrame] = RF;
		RecFrames = math.max(RecFrames, emu.framecount()-StartFrame);
	end;
	for k = MAX_PLAYER_INDEX,0,-1 do
			for  l = 1,MONITORED_BUTTON_COUNT,1 do
				if not inpm[i[l+k*INPUT_BUTTON_COUNT]] then
				  gui.text(10+k*70+l*MONITORED_BUTTON_COUNT,20,visualtbl[l],'black')
				else
				  gui.text(10+k*70+l*MONITORED_BUTTON_COUNT,20,visualtbl[l],'red')
				end;

			end;
	end;
	for FL = 1,math.min(MAX_DISPLAY_LINES,RecFrames - (emu.framecount()-StartFrame)),1 do
		FData = AllFrames[emu.framecount()-StartFrame+FL];

		for k = (PLAYER_COUNT-1),0,-1 do
					ct = FData[k+1];
					for l = 1,MONITORED_BUTTON_COUNT,1 do
						if math.mod(ct,2) == 1 then
					  		gui.text(10+k*70+l*MONITORED_BUTTON_COUNT,20+FL*MONITORED_BUTTON_COUNT,visualtbl[l],'red')
						end;
						ct = math.floor(ct/2);
					end;
		end;
	end;
gui.text(1,1,'Recording: ' .. NameTable[character_being_recorded]);
end;

emu.registerbefore(test);

while true do
	emu.frameadvance();
	afterframe();
end;
