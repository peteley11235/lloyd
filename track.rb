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

# Tracking plugin. Someday I hope to make this more dynamic, but for
# now each trackable thing is hardcoded.

require 'cinch'
require 'sqlite3'

class Track
  include Cinch::Plugin

  def initialize(*args)
    super

    @db = SQLite3::Database.open("#{$dir}/track.db")
    @db.results_as_hash = true

    # Keep track of canfield winnings
    @canfield_winnings = 0
    @db.execute "SELECT * FROM Canfield" do |rec|
      @canfield_winnings += rec["Money"]
    end
  end

  # Canfield
  match /canfield (\d+)/i, :method => :add_canfield
  def add_canfield(m,cards)
    cards = cards.to_i
    # Each card is worth $5, minus the initial buyin of $50. If you
    # win (get all cards) you get an automatic $500.
    money = cards * 5 - 50
    money = 500 if cards == 52
    # In this case, time != money
    time = Time.now.to_i
    synchronize(:track) do
      @db.execute "INSERT INTO Canfield (Time,Money) VALUES (#{time},#{money})"
      @canfield_winnings += money
    end
    m.reply("Added. Balance: $#{@canfield_winnings}")
  end

  match /canfield bal/i, :method => :canfield_balance
  def canfield_balance(m)
    m.reply("Your winnings so far: $#{@canfield_winnings}")
  end

  # Water drinking
  match /drank (\d+)/i, :method => :add_water
  def add_water(m,cups)
    time = Time.now.to_i
    synchronize(:track) do
      @db.execute "INSERT INTO Water (Time,Cups) VALUES (#{time},#{cups})"
    end
    m.reply("Added.")
  end

  # Rounds
  match /rounds (\w+)/i, :method => :rounds
  def rounds(m,name)
    time = Time.now.to_i
    synchronize(:track) do
      @db.execute "INSERT INTO Rounds (Time,Name) VALUES (#{time},'#{name}')"
    end
    m.reply("Added.")
  end
end
