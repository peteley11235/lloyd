# This work is licensed under the Creative Commons
# Attribution-ShareAlike 3.0 Unported License. To view a copy of this
# license, visit http://creativecommons.org/licenses/by-sa/3.0/.

# Cinch plugin for using bitlbee

require 'cinch'

class Bitlbee
  include Cinch::Plugin

  def initialize(*args)
    super
    
    f = File.open("#{$dir}/password","r")
    @pass = f.gets
    f.close
  end

  # Hack: this is the only unique code that won't be issued again for
  # the session (or so I think). For some reason, more conventional
  # events aren't workng. 
  listen_to :"324", :method => :identify
  
  # Finally got the password out of the damn code
  def identify(m)
    m.reply "identify #{@pass}"
  end
end
