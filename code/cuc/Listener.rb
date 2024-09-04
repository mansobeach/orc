#!/usr/bin/env ruby

#########################################################################
###
### = Ruby source for #Listener class
###
### = Written by DEIMOS Space S.L. (bolf)
###
### = Data Exchange Component -> Common Utils Component
### 
### Git:
###   $Id: Listener.rb,v 1.1 2006/09/11 16:46:55 decdev Exp $
###
#########################################################################

   # This class implements a generic listener (daemon).
   # It is checked that it is not running a listener with a given name.

require "cuc/CheckerProcessUniqueness"

module CUC

class Listener

   #-------------------------------------------------------------
   
   # Class constructor.
   # IN Parameters:
   # * string: the name of the listener process.
   # * string: param of the listener process.
   # * integer: time interval <seconds> it is performed the listener required action.
   # * proc: an object Proc which is the action to be performed in the body of the run.
   # First of all check if it is already running.
   # Only one process Listener is allowed.
   def initialize(name, param, interval, action, startTime = nil)
     checkModuleIntegrity
     @locker = CheckerProcessUniqueness.new(name, param, true)
     if @locker.isRunning == true then
        puts "\n#{name} #{param} is already running !\n\n"
        exit(99)
     end
     @param       = param
     @interval    = interval
     @startTime   = startTime
     @action      = action
     @isDebugMode = false
     @isForceMode = false
     @waitSecs    = calculateWaitSeconds
   end   
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "Listener debug mode is on"
   end
   #-------------------------------------------------------------

   # Set the flag for debugging on
   def setForceMode
      @isForceMode = true
      puts "Listener Force mode is on"
   end
   #-------------------------------------------------------------
   
   # Main method of the class. It starts the listener.
   # Every @interval time, the @action is done.
   # Now the interval time is a dynamic value returned by
   # the @action performed.
   def run
      daemonize
      wait4StartTime
      while true
         interval = @action.call()
         sleep(interval)
      end
   end
   #-------------------------------------------------------------

   def exec(cmd)
      daemonize
      wait4StartTime

      while true
        if @isDebugMode == true then
           puts "Executing #{cmd} with forced Interval #{@interval}"
           puts
        end
   

        childPid = fork{
            puts "Children PID is #{Process.pid}"
            system(cmd)
        }

        if childPid != 0 then
           if @isDebugMode == true then
              puts "New process #{childPid} created"
              puts
           end

           Process.detach(childPid)
        end

 
        if @isDebugMode == true then
           puts Time.now
           puts
           puts "sleeping #{@interval} seconds"
           puts
        end
        
        sleep(@interval)

        if childPid != 0 then
          # pid = Process.waitpid(childPid, Process::WNOHANG)

           if @isDebugMode == true then
              puts "Killing process #{childPid}"
              puts
           end
           begin
               Process.kill(9, childPid)
           rescue Exception => e
           end
        end


        if @isDebugMode == true then
           puts Time.now
           puts 
        end

        sleep(1)
        # Process.kill(9, pid)
      end
   end
   #-------------------------------------------------------------
   def exec2(cmd)
      daemonize
      wait4StartTime
      while true
        if @isDebugMode == true then
           puts "Executing #{cmd} with forced Interval #{@interval}"
           puts
        end
   
        pipe = IO.popen(cmd)
        pid  = pipe.pid
 
        if @isDebugMode == true then
           puts Time.now
           puts
           puts "sleeping #{@interval} seconds"
           puts
        end
        
        sleep(@interval)

        if @isDebugMode == true then
           puts Time.now
           puts 
           puts "Killing process #{pid}"
           puts
        end

        if @isDebugMode == true then
          # puts pipe.readlines
           puts
        end

        pipe.close
       
        begin
            Process.kill(9, pid)
        rescue Exception => e
        
        end
      end
   end
   #-------------------------------------------------------------

private

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true     
      if !ENV.include?('DCC_TMP') and !ENV.include?('DEC_TMP') and !ENV.include?('ORC_TMP') then
         puts "\nDCC_TMP | DEC_TMP | ORC_TMP environment variable not defined !\n"
         bDefined = false
      end      
      if bDefined == false then
         puts "\nError in Listener::checkModuleIntegrity :-(\n\n"
         exit(99)
      end                  

      if ENV.include?('DCC_TMP') then
         @tmpDir   = ENV['DCC_TMP']
      end

      if ENV.include?('DEC_TMP') then
         @tmpDir   = ENV['DEC_TMP']
      end
         
      if ENV.include?('ORC_TMP') then
         @tmpDir   = ENV['ORC_TMP']
      end

        
                         
   end
   ## -----------------------------------------------------------

   ## Become a nasty and cruel daemon in the system.
   def daemonize
   
      # Parent exists, child continue
      exit!(0) if fork
   
      # Become session leader without a controlling TTY
      Process.setsid
   
      exit!(0) if fork
      
      # Run at a higher priority
      #   Process.setpriority(Process::PRIO_PROCESS, 0, -10)
   
      Dir.chdir("/")   
      File.umask(0000)
   
      # puts "#{File.basename($0)} #{@param} set as daemon with pid #{Process.pid}\n\n"
   
      # Redirect standard streams    
      STDIN.reopen("/dev/null")
  
      if @isDebugMode == false then
         STDOUT.reopen("/dev/null")
         STDERR.reopen STDOUT
      end
           
      # Register in lock file the daemon
      @locker.setRunning      
   end
   ## -----------------------------------------------------------

   def calculateWaitSeconds
      waitSecs    = 0
      if @startTime != nil then
         currentTime = Time.now
         @startHour  = @startTime.split(":")[0].to_i
         @startMin   = @startTime.split(":")[1].to_i
         currentHour = currentTime.hour.to_i
         currentMin  = currentTime.min.to_i
         currentSec  = currentTime.sec.to_i

         currentSecs = currentMin*60 + currentHour*60*60 + currentSec
         startSecs   = @startMin*60 + @startHour*60*60

         if startSecs > currentSecs then
            waitSecs = startSecs - currentSecs
         else
            waitSecs = 86400 - currentSecs + startSecs
         end         
      end      
      return waitSecs
   end
   #-------------------------------------------------------------

   def wait4StartTime
      if @waitSecs > 0 then
         if @isDebugMode == true then
            puts "Waiting #{@waitSecs} to meet start time #{@startTime}"
            puts
         end
         sleep(@waitSecs)
      end
   end
   #-------------------------------------------------------------

end # class

end # module
