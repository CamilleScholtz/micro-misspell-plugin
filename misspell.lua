VERSION = "0.2.0"

local micro = import("micro")
local config = import("micro/config")
local shell = import("micro/shell")
local buffer = import("micro/buffer")


function split(str, sep)
    local result = {}
    local regex = ("([^%s]+)"):format(sep)
    for each in str:gmatch(regex) do
        table.insert(result, each)
    end
    return result
end

function basename(file)
    local name = string.gsub(file, "(.*/)(.*)", "%2")
    return name
end

function onSave(bufpane)
    if config.GetGlobalOption("misspell") then
        runMisspell(bufpane)
    else
        micro.CurPane():ClearAllGutterMessages()
    end
end

function onExit(output, args)
    local lines = split(output, "\n")
	local errorformat = args[1]

    local regex = errorformat:gsub("%%f", "(..-)"):gsub("%%l", "(%d+)"):gsub("%%m", "(.+)")
    for _,line in ipairs(lines) do
        -- Trim whitespace
        line = line:match("^%s*(.+)%s*$")
        if string.find(line, regex) then
            local file, line, msg = string.match(line, regex)
            if basename(micro.CurPane().Buf.Path) == basename(file) then
				local gutm = buffer.NewMessageAtLine("misspell", msg, tonumber(line), 2)
                micro.CurPane().Buf:AddMessage(gutm)
            end
        end
    end
end

function misspellCommand(bufpane, arguments)
    bufpane:Save(false)
    runMisspell(bufpane)
end

function runMisspell(bufpane)
    micro.CurPane().Buf:ClearMessages("misspell")
    local path = micro.CurPane().Buf.Path
    shell.JobSpawn("misspell", {path}, nil, nil, onExit, "%f:%l:%d+: %m")
end

function init()
	if config.GetGlobalOption("misspell") == nil then
    	config.SetGlobalOption("misspell", "true")
	end
	config.MakeCommand("misspell", misspellCommand, nil)
end
