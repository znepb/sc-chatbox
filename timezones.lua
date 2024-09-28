local box = require("box")
local chatbox = box.new()

local dataFile = "data.lua"
local firstExecsFile = "firstExecs.lua"

local ratelimits = {}
local data = {}
local firstExecs = {}

-- Utils
local function readFile(f)
  local f = fs.open(f, "r")
  local d = f.readAll()
  f.close()
  return d
end

local function writeFile(f, d)
  local f = fs.open(f, "w")
  f.write(d)
  f.close()
end

local function saveData()
  writeFile(dataFile, textutils.serialise(data))
  writeFile(firstExecsFile, textutils.serialise(firstExecs))
end

local function findSuffix(number)
  if number % 100 > 10 and number % 100 < 20 then
    return tostring(number) .. "th"
  elseif number % 10 == 1 then
    return tostring(number) .. "st"
  elseif number % 10 == 2 then
    return tostring(number) .. "nd"
  elseif number % 10 == 3 then
    return tostring(number) .. "rd"
  else
    return tostring(number) .. "th"
  end
end

-- Load data.json
data = textutils.unserialise(readFile(dataFile))
firstExecs = textutils.unserialise(readFile(firstExecsFile))

-- ======== --
-- COMMANDS --
-- ======== --

local command = chatbox
  .addAlias("top")
  .setName("&aTop")
  .onExecute(function(reply, args)
    local t = {}
    for i, v in pairs(data) do
      table.insert(t, {
        count = v,
        name = i
      })
    end
    table.sort(t, function (a, b) return a.count > b.count end)

    if args[1] == "command" and args[2] then
      local count = data[args[2]]
      if count == nil then
        return false, args[2] .. " has never been executed."
      end

      for i, v in pairs(t) do
        if v.name == args[2] then
          local firstExecInfo = firstExecs[v.name] and " It was first executed on " .. os.date("%A, %B %d, %Y at %X UTC", firstExecs[v.name].time / 1000) .. " by " .. firstExecs[v.name].user .. "." or " This command does not have first execution data stored yet."
          reply(args[2] .. " has been invoked " .. v.count .. " times. It is the " .. findSuffix(i) .. " most popular command." .. firstExecInfo)
          return
        end
      end

      return false, args[2] .. " has never been executed."
    elseif tonumber(args[1]) then
      local startAt = math.max(1, tonumber(args[1]))
      local response = "\n&aPlace #" .. tostring(startAt) .. " to #" .. tostring(startAt + 17)

      for i = startAt, startAt + 17 do
        local info = t[i]
        if info then
          response = response .. ("\n&a%d. &f%s &7(%d execution%s)"):format(i, info.name, info.count, info.count ~= 1 and "s" or "")
        end
      end

      response = response .. ("\n&eNext 18: &f\\top %d, &eprevious 18: &f\\top %d"):format(startAt + 18, math.max(1, startAt - 18))

      reply(response, "format")
    else
      local response = "\n&aTop 18 commands"

      for i = 1, 18 do
        local info = t[i]
        if info then
          response = response .. ("\n&a%d. &f%s &7(%d executions)"):format(i, info.name, info.count)
        end
      end

      response = response .. "\n&eUse \\top 19 to see next 18 top commands"

      reply(response, "format")
    end
  end)

-- Help
command.createSubcommand().addAlias("help").onExecute(function(reply, args, _, user)
  reply([[
This bot tracks top \ command invoctians since June 12, 2023. First execution time and first executors are stored since November 7th, 2023.
- You can view the information for a specific command via \top command <command>.
- \top <number> will show the 18 most popular commands starting at that position.
This bot is maintained by znepb.
  ]], "format")
end)

local function handleCommand(e)
  local command = e[3]

  if data[command] == nil then
    data[command] = 0
  end

  local user = e[5].user.uuid
  if ratelimits[user] then
    local limit = ratelimits[user]

    if limit.count >= 3 and (os.epoch("utc") - limit.startAt) / 1000 < 7.5 then
      print("Rate limit!", e[2])
      return
    elseif (os.epoch("utc") - limit.startAt) / 1000 >= 7.5 then
      ratelimits[user] = {
        startAt = os.epoch("utc"),
        count = 1
      }
    else
      ratelimits[user] = {
        startAt = os.epoch("utc"),
        count = limit.count + 1
      }
    end
  else
    ratelimits[user] = {
      startAt = os.epoch("utc"),
      count = 1
    }
  end

  if data[command] == nil then
    data[command] = 1
  else
    data[command] = data[command] + 1
  end

  if firstExecs[command] == nil then
    firstExecs[command] = {
      user = e[2],
      time = os.epoch("utc")
    }
  end

  saveData()
end

while true do
  local e = {os.pullEvent()}
  chatbox.onEvent(e)

  if e[1] == "command" then
    handleCommand(e)
  end
end
