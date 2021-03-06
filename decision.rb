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

# Makes decisions for you.

require 'cinch'

# for delayed_reply
require './helpers.rb'

class Decision
  include Cinch::Plugin

  # Simple coin flip
  match /coin/i, :method => :coin
  def coin(m)
    delayed_reply(m,rand(2) == 0 ? "Heads" : "Tails")
  end

  # Decide from a list of choices separated by "or" 
  # (Got the idea from #nethack bot Rodney's !rng)
  match /decide (.+)/i, :method => :decide
  def decide(m,str)
    choices = str.split(/, | or /)
    delayed_reply(m,choices[rand(choices.size)])
  end
end
