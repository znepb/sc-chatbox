local expectcc = require("cc.expect")
local field = expectcc.field
local expect = expectcc.expect

local MAX_SUBCOMMAND_DEPTH = 8

local box = {
  __internal = {
    basicCommand = {}
  },
  subcommand = {},
}

local function subTable(array, from, to)
  local output = {}

  if from and to then
    for i = from, to do
      output[#output + 1] = array[i]
    end
  elseif from == nil and to then
    for i = 1, to do
      output[#output + 1] = array[i]
    end
  elseif from and to == nil then
    for i = from, #array do
      output[#output + 1] = array[i]
    end
  end

  return output
end

local function log(level, ...)
  local levelColors = {
    debug = colors.gray,
    info = colors.white,
    error = colors.red,
    warning = colors.yellow
  }

  term.setTextColor(levelColors[level])
  print(("[%s]"):format(os.date("%X")), ...)
end

--- Creates a BasicCommand. This should only be used internally.
function box.__internal.basicCommand.new()
  local self = {}
  local isOwnerOnly = false
  local onExecute
  local command
  local parent
  local format

  self.aliases = {}
  self.__internal = {}
  self.__internal.children = {}

  function self.__internal.setCommand(newCommand)
    command = newCommand
  end

  function self.__internal.setParent(newParent)
    parent = newParent
  end

  function self.__internal.findChild(arg)
    for i, v in pairs(self.__internal.children) do
      if v.aliases[arg] == true then return v end
    end
  end

  --- Creates a new subcommand.
  -- @return The created subcommand/
  function self.createSubcommand()
    local newSubcommand = box.subcommand.new(parent.__internal.getArgIndex() + 1)
    table.insert(self.__internal.children, newSubcommand)
    newSubcommand.__internal.setCommand(command)
    return newSubcommand
  end

  --- Should be executed when an event is fired on the system.
  function self.onEvent(e)
    if e[1] == "command" then
      local _, user, executed, args, data = unpack(e)

      local function reply(text, mode, tellname)
        log("debug", "Replying to", user, "with", text)
        command.tell(user, text, mode, tellname)
      end

      -- Check if this command is for use by owners only
      if isOwnerOnly and data.ownerOnly == false then return end

      -- Check if the command matches all the specified aliases
      if command.aliases[executed] then
        if parent.__isRoot then log("debug", "Received command event") end
        local subcommand = args[parent.__internal.getArgIndex() + 1]

        if subcommand and self.__internal.findChild(subcommand) then
          local childWithSubcommand = self.__internal.findChild(subcommand)
          childWithSubcommand.onEvent(e)
        elseif type(onExecute) == "function" then
          log("info", "Executing command:", executed, table.concat(args, " "), "from", user)
          local result, msg, at = onExecute(reply, subTable(args, parent.__internal.getArgIndex() + 1), user, data.user)

          if result == false then
            -- The result returned was specified as invalid
            if at then
              -- A position was specified where the user made a mistake specifically, respond with some helpful info
              local arg = at.arg
              local index = at.index
              local startingIndex = parent.__internal.getArgIndex() + 1

              local replyData = "&c" .. (msg or "Incorrect argument for command") .. "\n&7" .. executed
                .. (#args > 1 and " " .. table.concat(subTable(args, nil, startingIndex - 1), " ") or "")

              for i = startingIndex, #args do
                local v = args[i]

                print(arg, i-startingIndex + 1)

                if arg == (i - startingIndex + 1) then
                  replyData = replyData .. " &c&n" .. v:sub(1, index) .. "&c&o<--[HERE]"
                  break
                end

                replyData = replyData .. " " .. v
              end
              reply(replyData, "format")
            elseif msg then
              -- Only a message was specified, respond with that
              reply("&c" .. msg, "format")
            else
              -- Generic error message, no child argument
              reply(
                "&cIncorrect argument for command\n&7"
                .. executed
                .. (#args > 1 and " " .. table.concat(subTable(args, nil, #args - 1), " ") or "")
                .. " &c&n" .. args[#args] .. "&c&o<--[HERE]"
              , "format")
            end
          end
        elseif type(onExecute) == "string" then
          log("info", "Executing command:", executed, table.concat(args, " "), "from", user)
          reply(onExecute, format)
        else
          local subcommands = {}
          for i, v in pairs(self.__internal.children) do
            for a in pairs(v.aliases) do
              table.insert(subcommands, a)
            end
          end

          -- No child argument
          reply(
            "&cIncorrect argument for command\n&7"
            .. executed
            .. (#args > 0 and " &c&n" .. table.concat(subTable(args, nil, #args), " ") or "")
            .. "&c&o<--[HERE]\n&cValid subcommands: &o" .. table.concat(subcommands, ", ")
          , "format")
        end
      end
    end
  end

  --- Adds a new alias for this command or subcommand.
  -- @tparam string alias The alias to add.
  -- @return This
  function self.addAlias(alias)
    expect(1, alias, "string")
    self.aliases[alias] = true
    return parent
  end

  --- Removes an existing alias for this command or subcommand.
  -- @tparam string alias The alias to remove.
  -- @return This
  function self.removeAlias(alias)
    expect(1, alias, "string")
    self.aliases[alias] = nil
    return parent
  end

  --- Sets whether or not this command should only be able to be executed by the chatbox's owner. If the parent command or subcommand is set to be owner only, this command will error.
  -- @tparam boolean shouldBeOwnerOnly Whether or not this command should be owner-only.
  -- @return This
  function self.setOwnerOnly(shouldBeOwnerOnly)
    expect(1, shouldBeOwnerOnly, "boolean")
    isOwnerOnly = shouldBeOwnerOnly
    return parent
  end

  --- Sets the function that will ran, or text that will be sent, when the command or subcommand is fired.
  --- If this isn't set, this command will return false.
  --- The function should have the following return arguments. They are all optional:
  --- - boolean, whether or not the command succeeded. If this is false, the next two return values will take effect.
  --- - string, optional, the message to sent to the user.
  --- - at, optional, where in the command the error occured. This should be a table with two indexes: arg, which argument failed, and index, the string index of that argument where it failed.
  -- @tparam[opt] function|string func The function to execute.
  -- @tparam[opt] string format The format to use if the first argument is a string/
  -- @return This
  function self.onExecute(func, newFormat)
    expect(1, func, "string", "function", "nil")
    expect(2, newFormat, "string", "nil")
    onExecute = func
    format = newFormat
    return parent
  end

  --- Returns if this command is owner-only
  -- @return Whether or not this command is owner-only
  function self.isOwnerOnly()
    return isOwnerOnly
  end

  return self
end

--- Creates a new subcommand. This class should only be initalized by createSubcommand in a subcommand or command instance. Inherits BasicCommand.
function box.subcommand.new(argIndex)
  local self = {}
  self = box.__internal.basicCommand.new(command, self)
  self.__internal.setParent(self)

  if argIndex > MAX_SUBCOMMAND_DEPTH then
    error("Max subcommand depth reached (" .. tostring(MAX_SUBCOMMAND_DEPTH) .. ")")
  end

  function self.__internal.getArgIndex()
    return argIndex
  end

  --- Sets whether or not this command should only be able to be executed by the chatbox's owner. If the parent command or subcommand is set to be owner only, this command will error.
  -- @tparam boolean shouldBeOwnerOnly Whether or not this command should be owner-only.
  -- @return This
  function self.setOwnerOnly(shouldBeOwnerOnly)
    expect(1, shouldBeOwnerOnly, "boolean")
    if parentCommand.isOwnerOnly() == true then
      error("Children of owner only commands cannot have their owner only status changed.")
    end
    self.setOwnerOnly(shouldBeOwnerOnly)
    return self
  end

  return self
end

--- Creates a new command.
function box.new()
  local self = {}
  self = box.__internal.basicCommand.new(self, self)
  local name

  self.__internal.setCommand(self)
  self.__internal.setParent(self)
  self.__index = self
  self.__isRoot = true

  --- Sets the name used when .tell is executed.
  -- @tparam name string The name to set.
  -- @return this
  function self.setName(newName)
    expect(1, newName, "string", "nil")
    name = newName
    return self
  end

  --- Executes chatbox.tell, inheriting name from the set name.
  -- @tparam who string Who to send the message to.
  -- @tparam text string The text to send
  -- @tparam[opt] mode string The mode to use (markdown or format)
  -- @tparam[opt] name string The name to use when sending. If nil, this will default to what was set with .setName, if it was set.
  -- @return This
  function self.tell(who, text, mode, tellname)
    expect(1, who, "string")
    expect(2, text, "string")
    expect(3, mode, "string", "nil")
    expect(4, tellname, "string", "nil")
    chatbox.tell(who, text, name or tellname, nil, mode)
    return self
  end

  function self.listen(raw)
    while true do
      self.onEvent( { os.pullEvent() } )
    end
  end

  function self.__internal.getArgIndex()
    return 0
  end

  log("info", "Ready!")

  return self
end

return box