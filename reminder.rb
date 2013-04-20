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

# Lloyd reminders plugin. When I tell him something like "remind me
# once to feed the dog in 10 minutes" he does so.

require 'cinch'
require 'chronic'
require 'chronic_duration'

class Reminder
  class ReminderStruct < Struct.new(:who, :time, :msg, :r_int)
    def to_s
      "#{who},#{time},#{msg},#{r_int}\n"
    end
  end
  
  include Cinch::Plugin
  
  def initialize (*args)
    super
    
    # Use a simple flat file to store reminders
    # in case of a shutdown. 
    @reminderfile = "#{$dir}/reminders"
    
    read_reminders

    # Remove old reminders every half hour
    Timer(30*60) { clean_reminder_file }
  end
  
  # read the reminders from the file
  def read_reminders
    synchronize(:reminderfile) do
      File.open(@reminderfile,"r").each do |line| 
        (w,t,m,r) = line.split(",")
        # discard reminders whose times have passed
        remind(ReminderStruct.new(w,t,m,r)) if t.to_i > Time.now.to_i
      end
    end
  end

  # write a single reminder to the file
  def write_reminder(r)
    synchronize(:reminderfile) do
      f = File.open(@reminderfile,"a")
      f.write(r)
      f.close
    end
  end

  # Remove old reminders from the file
  def clean_reminder_file
    reminders = []
    synchronize(:reminderfile) do
      File.open(@reminderfile,"r").each do |line|
        (w,t,m,r) = line.split(",")
        reminders.push(line) unless t.to_i < Time.now.to_i
      end
      f = File.open(@reminderfile,"w")
      reminders.each { |rem| f.write(rem) }
      f.close
    end
  end

  # Reminder logic
  match /remind me (o|d|w|m|y)?.*?\b (.+) (in|at) (.+)/i, :method => :add_reminder
  def add_reminder(m,repeat,msg,inat,timestr)
    # remove some phrases out of the msg
    # e.g. "to pay bills" gives a "pay bills"
    # message
    subs = [ 
            /^to /,
            /^of /,
            /^about /,
            /^that /
           ]
    subs.each { |s| msg.sub!(s,"") }

    # calculate time and repeat interval
    case repeat
    when "o"
      r_int = 0
      case inat 
      when "at" 
        time = Chronic::parse(timestr).to_i
      when "in"
        time = Time.now.to_i + ChronicDuration::parse(timestr)
      else
        m.reply("usage: remind me <once/daily/weekly/monthly/yearly> <text> <in/at> <time>")
        return 0
      end
    when /[dwmy]/
      # otherwise, ChronicDuration will assume 'minute'
      repeat = "month" if repeat == "m"
      r_int = ChronicDuration::parse(repeat)
      case inat
      when "at"
        time = Chronic::parse(timestr).to_i
      when "in"
        time = Time.now.to_i + ChronicDuration::parse(timestr)
      else
        m.reply("usage: remind me <once/daily/weekly/monthly/yearly> <text> <in/at> <time>")
      end
    end

    r = ReminderStruct.new(m.user.nick,time,msg,r_int)
    write_reminder(r)
    remind(r)
  end

  # Set up the once/recurring reminder timer for a given struct. I
  # could use 0 shots for infinite repeats, but that only works if the
  # interval between now and the time is the same as the repeat
  # interval. This way, each timer is a one-off that sets up another
  # one as it ends. Kinda clever if you ask me.
  def remind(r)
    send_message = lambda {
      User(r.who).msg("#{r.msg}")
      Timer(r.r_int.to_i, :shots => 1, &send_message) unless r.r_int.to_i == 0
    }

    Timer(r.time.to_i-Time.now.to_i, :shots => 1, &send_message)
  end
end
