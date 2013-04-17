#!/usr/bin/ruby1.9.1

# This work is licensed under the Creative Commons
# Attribution-ShareAlike 3.0 Unported License. To view a copy of this
# license, visit http://creativecommons.org/licenses/by-sa/3.0/.

# Lloyd is my personal assistant. He is an IRC bot using the Cinch
# bot framework. He sits on Bitlbee, an IRC gateway to chat
# services like AIM. He has his own account on the im.bitlbee.org
# IRC network and AIM screenname which he uses for the free AIM SMS
# gateway. I communicate with him via text message. 

require 'cinch'

# plugins
require './bitlbee.rb'
require './reminder.rb'
require './decision.rb'

# directory to store databases and files
$dir = ENV['HOME']+'/.lloyd'

lloyd = Cinch::Bot.new do

  f = File.open("#{$dir}/user","r")
  user = f.gets
  f.close

  configure do |c|
    c.server = "im.bitlbee.org"
    c.nick = "#{user}"

    c.user = "#{user}"
    c.realname = "Lloyd Arisassistant"

    c.plugins.plugins = [
                         Bitlbee,
                         Reminder,
                         Decision
                        ]
    c.plugins.prefix = ""
  end
end

lloyd.start
