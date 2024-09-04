#!/usr/bin/ruby

#########################################################################
#
# Ruby source for #CommandLauncher class
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Exchange Component -> Common Utils Component
# 
# CVS:
#   $Id: CommandLauncher.rb,v 1.5 2008/07/02 10:03:07 decdev Exp $
#
#########################################################################

require 'cuc/Log4rLoggerFactory'

 # Module Common Utils Component
 # This module encapsulates all shell command calls in order to centralize
 # all command executions and perform a clean way for logging all errors.


module CUC

module CommandLauncher

   ## -----------------------------------------------------------
   ## It performs the execution of a system command.
   
   def execute(cmd, subSystem = "", bAbort = false, bPrintConsole = false, bLogResult = true, bCaptureStdError = true)
      bRet   = false
      output = ""
      
      if bCaptureStdError == true then
      	 output = `#{cmd} 2>&1`
      else
      	 output = `#{cmd} 2> /dev/null`
      end

      if bPrintConsole == true then
         puts output
      end
      
      STDERR.reopen(STDOUT)

      if $? !=0 then
         bRet = false
      else
         bRet = true
      end
      
      if bRet == false then
      	 if bLogResult == true then      
            log_execution("[DEC_628] exec failed: #{cmd}", subSystem)
            arrLines = output.split("\n")
            arrLines.each{|line|
            	if line != "" and line != "false" then
                  log_execution("[DEC_628] exec output: #{line}", subSystem)
            	end
            }
	      end
      end      
      
      if bRet == false and bAbort == true then
         exit(99)
      end
      return(bRet)
   end
   ## -----------------------------------------------------------

private
   
   ## -----------------------------------------------------------
   
   ## Log the execution of the command
   def log_execution(msg, header)

      configDir = nil

      if ENV['DEC_CONFIG'] then
         configDir         = %Q{#{ENV['DEC_CONFIG']}}  
      end

      loggerFactory = CUC::Log4rLoggerFactory.new("#{header}", "#{configDir}/dec_log_config.xml")
      if @isDebugMode then
         loggerFactory.setDebugMode
      end
      logger = loggerFactory.getLogger
      if logger == nil then
         puts
			puts "Error in CommandLauncher::log_execution"
			puts "Could not set up logging system !  :-("
         puts "Check DEC logs configuration under \"#{configDir}/dec_log_config.xml\"" 
			puts
			puts
			exit(99)
      end

      logger.error(msg)
   end
   ## -----------------------------------------------------------
   
end # module

end # module
