#!/usr/bin/ruby

#########################################################################
#
# Ruby source for #Logger class
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Exchange Component -> Common Utils Component
# 
# CVS:
#   $Id: Logger.rb,v 1.1 2006/09/06 14:32:54 decdev Exp $
#
#########################################################################

LOG_NONE        = ""
LOG_ERROR       = " ERROR "
LOG_INFORMATION = " INFO  "
LOG_WARNING     = "WARNING"

require 'thread'

 # Module Common Utils Component
 # This class implements a generic File Logger.

module CUC

class Logger

   #-------------------------------------------------------------
   
   # Class constructor.
   # IN parameters:
   # * string - full path filename of the log.
   # * bool   - register time for each entry   
   def initialize(fullPathFilename, bRegisterTime, otherInformation="")
      checkModuleIntegrity
      @file = nil      
      begin
         @file   = File.new(fullPathFilename, File::CREAT|File::APPEND|File::WRONLY, 0600)
      rescue
         puts 
         puts "#{otherInformation}Logger could not create Log file #{fullPathFilename}!"
         puts "#{otherInformation}Log is disabled"
         puts
      end
    
      @@mutex = Mutex.new
      @otherInformation = otherInformation.slice(0,13)
      if otherInformation.to_s != "" then
#         @otherInformation = @otherInformation.upcase
         @otherInformation = @otherInformation.ljust(13) 
      end
      @bRegisterTime = bRegisterTime
   end   
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "Logger debug mode is on"
   end
   #-------------------------------------------------------------
   
   # Log a message into the log file
   # IN parameters:
   # * string - message to be written into the log.
   # * string - severity of the log message
   # * bool   - Flag to show the message in the console
   def log (msg, severity = LOG_INFORMATION, bConsole = false)
      message = %Q{#{severity.ljust(7)} - #{msg}}
      writeline(message, severity, bConsole)
   end
   #-------------------------------------------------------------
   
   # Write a line into the log file.
   #
   # First Lock The File at thread level.
   # This mutex is useless at process level.
   # Before writing, it locks exclusively the file
   # for current process.
   def writeln(line)
      if @file == nil then
         return
      end
      writeline(line)
   end
   #-------------------------------------------------------------

private
   
   # Class variable for blocking access.
   # It works only at Thread level.
   # It is not really efective if the class is instanced by different
   # processes, as they run in a different interpreter.
   @@mutex = nil
   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      return                                 
   end
   #-------------------------------------------------------------

   # Return [string] current UTC Time in the format set below.
   def getCurrentTime
      time = Time.new
      time.utc
      return time.strftime("[%Y-%m-%d %H:%M:%S]")
   end
   #-------------------------------------------------------------
      
   # Write the line
   def writeline(line, severity = LOG_INFORMATION, bConsoleOutput = false)
      @@mutex.synchronize do
      
         @file.flock(File::LOCK_EX)
         
         header = ""
         if @bRegisterTime == true then
            time   = getCurrentTime
            header = %Q{#{time} -}
         end
         if @otherInformation != "" then
            header = %Q{#{header} #{@otherInformation} -}
         end
         line = %Q{#{header} #{line}}
         @file.puts(line)
         
         # If ConsoleOutput is true the message is sent to the console.
         # Depending on the severity the message is sent to STDERR or STDOUT stream
         if bConsoleOutput == true then
            if severity == LOG_ERROR then
               STDERR.puts line
            else
               STDOUT.puts line
            end
         end
         
         @file.flock(File::LOCK_UN)
         
      end
   end
   #-------------------------------------------------------------
end # class

end # module
