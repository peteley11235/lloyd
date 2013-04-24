# This work is licensed under the Creative Commons
# Attribution-ShareAlike 3.0 Unported License. To view a copy of this
# license, visit http://creativecommons.org/licenses/by-sa/3.0/.

# Lloyd reminders plugin. When I tell him something like "remind me
# once to feed the dog in 10 minutes" he does so.

require 'cinch'
require 'chronic'
require 'chronic_duration'

class Reminder
  class ReminderStruct < Struct.new(:who,:time,:msg,:r_int,:stopat)
    def to_s
      "#{who},#{time},#{msg},#{r_int},#{stopat}\n"
    end
  end
  
  include Cinch::Plugin
  
  def initialize (*args)
    super
    
    # Use a simple flat file to store reminders
    # in case of a shutdown. 
    @reminderfile = "#{$dir}/reminders"
    
    read_reminders

    # Remove old reminders every half hour (also called in
    # read_reminders)
    Timer(30*60) { clean_reminder_file }
  end
  
  # read the reminders from the file
  def read_reminders

    # Keep track of the reminders that will be kept
    kept_reminders = []

    synchronize(:reminderfile) do
      File.open(@reminderfile,"r").each do |line| 
        w,t,m,r,s = line.split(",")

        # Hack! 
        s = nil if s == "\n"

        # Update recurring reminders which have passed and either are
        # infinite (stopat=nil) or are still in their recur interval
        # (stopat in the future)
        if (t.to_i < Time.now.to_i) &&
            (r.to_i > 0) && 
            (s.nil? || (s.to_i > Time.now.to_i))
          time = t.to_i
          time += r.to_i until time > Time.now.to_i 
          t = time
          kept_reminders.push(ReminderStruct.new(w,t,m,r,s))
        end

        remind(ReminderStruct.new(w,t,m,r,s)) if t.to_i > Time.now.to_i
      end
    end
    
    clean_reminder_file

    # Have to do this outside 'synchronize' because 'write_reminder'
    # calls 'synchronize' and causes deadlock
    kept_reminders.each { |r| write_reminder(r) }
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

  # The important bit
  match /remind me (.+) (in|at) (?>(.+) (?>every (.+))|(.+))/i, :method => :add_reminder
  def add_reminder(m,reminder,*args)
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
    
    # The atomic (?>) group in the regex 
    # returns nil, and must be removed
    args.reject! { |a| a.nil? }

    # reverse the array so you can pop the
    # elements off in order
    args.reverse!

    # Time calculation
    inat = args.pop
    timestr = args.pop

    if inat == "at"
      time = Chronic.parse(timestr).to_i
    else
      time = Time.now.to_i + ChronicDuration.parse(timestr)
    end

    # Repeat interval calculation
    repeat = args.pop

    if repeat
      # Allow recurring reminders to be given
      # a set interval or time to stop
      if repeat.match(/(until|for)/)
        endtype = repeat.match(/(until|for)/)[0]
        repeat,endclause = repeat.split(" #{endtype} ")
        
        if endtype == "until"
          stopat = Chronic.parse(endclause).to_i
        elsif endtype == "for"
          stopat = time + ChronicDuration.parse(endclause)
        end
      else
        stopat = nil
      end
      r_int = ChronicDuration.parse(repeat)
    else
      r_int = 0
      stopat = nil
    end

    r = ReminderStruct.new(m.user.nick,time,reminder,r_int,stopat)

    # Feedback
    m.reply("Okay, I'll remind you at #{Time.at(time)}")

    write_reminder(r)
    remind(r)
  end

  # This sets up the timer for the interval between 
  # now and the time of the reminder (or the first
  # in a series of recurring reminders)
  def remind(r)
    Timer(r.time.to_i-Time.now.to_i, :shots => 1) { remind_iter(r) }
  end
      
  # This takes care of recurring reminders, both
  # infinitely recurring and those with a set
  # stop time
  def remind_iter(r)
    # Send first message
    User(r.who).msg(r.msg)

    # Set up recurring timers
    if r.r_int.to_i > 0

      # Infinitely recurring
      if r.stopat.nil?
        Timer(r.r_int.to_i) { User(r.who).msg(r.msg) }

      # Recurring over a set interval
      else
        shots = ((r.stopat.to_i-Time.now.to_i) / r.r_int.to_i) - 1
        Timer(r.r_int.to_i, :shots => shots) { User(r.who).msg(r.msg) }
      end
    end
  end
end
