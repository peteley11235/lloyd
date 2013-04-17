# This work is licensed under the Creative Commons
# Attribution-ShareAlike 3.0 Unported License. To view a copy of this
# license, visit http://creativecommons.org/licenses/by-sa/3.0/.

# Makes decisions for you.

require 'cinch'

class Decision
  include Cinch::Plugin

  # Simple coin flip
  match /coin/i, :method => :coin
  def coin(m)
    m.reply( rand(2) == 0 ? "Heads" : "Tails" )
  end

  # Decide from a list of choices separated by "or" 
  # (Got the idea from #nethack bot Rodney's !rng)
  match /decide (.+)/i, :method => :decide
  def decide(m,str)
    choices = str.split(/, | or /)
    m.reply(choices[rand(choices.size)])
  end
end
