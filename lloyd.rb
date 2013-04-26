#!/usr/bin/ruby1.9.1

# Copyright (c) 2013 Peter Ley 

# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Lloyd is my personal assistant. He is an IRC bot using the Cinch
# bot framework. He sits on Bitlbee, an IRC gateway to chat
# services like AIM. He has his own account on the im.bitlbee.org
# IRC network and AIM screenname which he uses for the free AIM SMS
# gateway. I communicate with him via text message. 

require 'cinch'
require 'daemons'

# plugins
require './bitlbee.rb'
require './reminder.rb'
require './decision.rb'
require './track.rb'

# directory to store databases and files
$dir = ENV['HOME']+'/.lloyd'

lloyd = Cinch::Bot.new do

  f = File.open("#{$dir}/user","r")
  user = f.gets
  f.close

  configure do |c|
    c.server = "im.bitlbee.org"
    c.nick = "#{user}"

    c.realname = "Lloyd Arisassistant"

    c.plugins.plugins = [
                         Bitlbee,
                         Reminder,
                         Decision,
                         Track
                        ]
    c.plugins.prefix = ""
  end
end

Daemons.run_proc('lloyd') do
  lloyd.start
end
