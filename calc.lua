local box = require("box")
local chatbox = box.new()

local function filterForSub(str)
  return str
    :gsub("%%", "%%%%")
    :gsub("%(", "%%%(") -- (
    :gsub("%)", "%%%)") -- )
    :gsub("%^", "%%%^")
    :gsub("%-", "%%%-")
    :gsub("%+", "%%%+")
    :gsub("%.", "%%%.")
    :gsub("%*", "%%%*")
end

local functions = {
  "abs", "acos", "asin", "atan", "ceil", "cos", "cosh", "deg", "floor", "log", "log10", "rad", "sin", "sinh", "sqrt", "tan", "tanh",
}

local function solveEquation(equation)
  for i, v in pairs(functions) do
    for m in string.gmatch(equation, v .. "%(.-%)") do
      local n = solveEquation(m:match(v .. "%((.-)%)"))
      equation = string.gsub(equation, filterForSub(m), tostring(math[v](tonumber(n))))
    end
  end

  return textutils.unserialise(equation)
end

chatbox
  .addAlias("calc")
  .addAlias("=")
  .addAlias("eval")
  .addAlias("calculate")
  .addAlias("c")
  .setName("calc")
  .onExecute(function(reply, args, _, user)
    if args[1] == nil then
      reply([[This command offers evaluation for simple and semi-complex equations. A few notes:
  - Most Lua math functions are available. The following functions are not available: atan2, exp, fmod, frexp, ldexp, max, min, pow, random and randomseed.
  - sin, cos, tan, and related functions use radians, just like Lua does.
  - `ans` can be entered to use the answer returned in the last equation.]])
      return
    end

    local result = nil

    local _, err = pcall(function()
      local equation = table.concat(args, " "):lower()

      equation = equation:gsub("pi", math.pi)
      equation = equation:gsub("huge", math.huge)
      equation = equation:gsub("ans", settings.get("calc.answer." .. user.uuid, result) or 0)
      result = solveEquation(equation)

      if result and args and (type(result) == "string" or type(result) == "number") then
        reply(table.concat(args, " ") .. " = `" .. result .. "`")
        settings.set("calc.answer." .. user.uuid, result)
        settings.save()
      end
    end)

    if result == nil or args == nil or not (type(result) ~= "string" or type(result) ~= "number") then
      print("Calc failed!", equation)
      return false, "Failed to calculate!"
    end
  end)

chatbox.listen()