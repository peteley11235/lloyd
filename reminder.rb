# This work is licensed under the Creative Commons
# Attribution-ShareAlike 3.0 Unported License. To view a copy of this
# license, visit http://creativecommons.org/licenses/by-sa/3.0/.

# Lloyd reminders plugin. When I tell him something like "remind me
# once to feed the dog in 10 minutes" he does so.

# TODO Rewrite file logic for recurring reminders

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
  match /remind me (.+) (in .+)/i, :method => :add_reminder
  match /remind me (.+) (at .+)/i, :method => :add_reminder
  def add_reminder(m,reminder,time)
    # remove some phrases out of the msg
    # e.g. "to pay bills" gives a "pay bills"
    # message
    subs = [ 
            /^to /,
            /^of /,
            /^about /,
            /^that /
           ]
    subs.each { |s| reminder.sub!(s,"") }

    # Convert the time into an epoch time string
    if time.match(/^in/) 
      time = Time.now.to_i + ChronicDuration.parse(time.sub(/in /,""))
    elsif time.match(/^at/)
      time = Chronic.parse(time.sub(/at /,""))
    end

    # temporary
    r_int = 0

    r = ReminderStruct.new(m.user.nick,time,reminder,r_int)
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
