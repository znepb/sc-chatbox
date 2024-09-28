local box = require("box")
local chatbox = box.new()

local ratelimit = 2 * 60 * 1000
local webhookLink = ""

local messageRateLimit = {}

chatbox.addAlias("snowflake").addAlias("zco").setName("&bSnowflake")

chatbox.createSubcommand()
  .addAlias("help")
  .onExecute([[
&f&oThis command gives some information on Snowflake Software (formally known as zCo).

&3Command List
&f\snowflake help
&7    Displays this message.
&f\snowflake members
&7    Tells you about the members of Snowflake.
&f\snowflake services, \snowflake products
&7    Lists products and services that we offer.
&f\snowflake message
&7    Sends a message straight to our inbox.
&f\snowflake locations
&7    Gives you some information on where you can find us.

&3Owned by Snowflake Software (https://snowflake.blue)
&3Voted "Best Fictional SC Company", June 2023*
]], "format")

chatbox.createSubcommand()
  .addAlias("members")
  .onExecute([[
&3Members
&bznepb &3- &fFounder, Co-Owner and Programmer
&bAutiOne &3- &fCo-Owner
&bEmmaKnijn &3- &fCo-Owner
&bPC_Cat &3- &fHead Programmer
]], "format")

chatbox.createSubcommand()
  .addAlias("services")
  .onExecute([[
&3Services
&f\balance
&7    A tool to view the balance of an address.
&f\calc
&7    A calculator bot.
&fcolorful.kst
&7    A shop that sells colorful blocks at cheap prices.
&7    Located at 136, 74, -138.
&fPrinting Services
&7    Cheap mass-poster printing. Located at 653, 73, 109.
&fSnowflake Terraforming & Building Services
&7    We'll build for you or terraform some land. Contact us
&7    via \snowflake message for details.
&f\top
&7    Tracks top commands since June 12th, 2023.
&fznepb's Shop
&7    Random crap for sale. Located in Catmall, at 65, 74, -68.
]], "format")

chatbox.createSubcommand()
  .addAlias("products")
  .onExecute([[
&3Products
&fCommon Shop Information
&7    Standarized method of storing shop information within a
&7    name's A record. See \csi for more.
&fTheater Rentals
&7    Rent space at zCo Theater for reasonable details. Contact
&7    us via \snowflake message for details.
&fSnowflake Farm Software
&7    A software package which features crop farms, tree
&7    farms, and central monitoring. For sale at znepb's Shop.
]], "format")

chatbox.createSubcommand()
  .addAlias("message")
  .onExecute(function(reply, args, user, data)
    if args[1] == nil then
      return false
    end

    if messageRateLimit[data.uuid] then
      if os.epoch("utc") < messageRateLimit[data.uuid] + ratelimit then
        local time = math.floor((messageRateLimit[data.uuid] + ratelimit - os.epoch("utc")) / 1000)
        local minutes = math.floor(time / 60)
        local seconds = time - minutes * 60
        return false, "You are being rate limited. You can send another message in " .. (minutes > 0 and ("%dm %ds."):format(minutes, seconds) or ("%ds."):format(seconds))
      end
    end

    reply("&3Message: &fSending your message...", "format")
    local res, err, a = http.post(webhookLink, textutils.serialiseJSON({
      embeds = {
        {
          title = "Message Received",
          description = table.concat(args, " "),
          color = 5570131,
          author = {
            name = user,
            icon_url = "https://mc-heads.net/head/" .. user
          },
          footer = {
            text = "Recevied via \\snowflake message at " .. os.date() .. " UTC"
          }
        }
      },
      username = "Snowflake Message Bot",
    }), {
      ["Content-Type"] = "application/json"
    })

    if res ~= nil then
      reply("&3Message: &aMessage sent successfully! &fWe will get back to you soon.", "format")
      messageRateLimit[data.uuid] = os.epoch("utc")
    else
      return false, "Message failed to send due to a technical error. Please try again later!"
    end
  end)

chatbox.createSubcommand()
  .addAlias("locations")
  .onExecute([[
&3Locations
&fJoseph R. Hawley Tower &7(293, 70, -186)
&fSnowflake Offices, Building #1 &7(706, 71, -6)
&fSnowflake Servers, Building #2 &7(687, 71, 35)
&fSnowflake Warehouse, Building #3 &7(761, 71, 93)
&fSnowflake SARS-CoV-2 Distrubtion Tower, Building #4 &7(651, 76, 82)
&fzCo Theater, Building #5 &7(684, 67, 217)
&fSnowflake Printing Services, Building #6 &7(654, 73, 107)
]], "format")

chatbox.listen()
