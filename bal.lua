local name = "balance"

while true do
  local e = { os.pullEvent() }

  if e[1] == "command" then
    local usr, cmd, args = e[2], e[3], e[4]
    if cmd == "bal" or cmd == "balance" then
      if args[1] == nil then
        chatbox.tell(usr, "Enter a valid Krist adress! (e.g. kznepbmewt)", "&a" .. name)
      else
        local data = nil

        if type(args[1]) ~= "string" and args[1]:sub(1, 2) ~= "k" or args[1]:len() ~= 10 then
          chatbox.tell(usr, "Enter a valid Krist adress! (e.g. kznepbmewt)", "&c" .. name)
        end

        local ok = pcall(function()
          local handle = http.get("https://krist.dev/addresses/" .. args[1])
          local data = textutils.unserialiseJSON(handle.readAll())
          handle.close()

          assert(data ~= nil)
          assert(data.ok)

          chatbox.tell(usr, args[1] .. "'s balance: **" .. data.address.balance .. "**\nTotal In, Total Out: **" .. data.address.totalin .. "**, **" .. data.address.totalout .. "**\nFirst Seen: **" .. data.address.firstseen .. "**", "&a" .. name)
        end)

        print(ok)

        if not ok then
          chatbox.tell(usr, "Failed to fetch balance of " .. args[1] .. ". Does the address exist?", "&c" .. name)
        end
      end
    end
  end
end
