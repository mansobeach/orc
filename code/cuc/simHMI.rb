#!/usr/bin/env ruby

# == Synopsis
#
# This is a Data Exchange Component command line tool that synchronizes the Entities configuration file
# with DEC Inventory. It extracts all the I/Fs from the interfaces.xml file and 
# inserts them in the DEC Inventory.
#
# As well it allows to specify a new I/F mnemonic to be loaded into the DEC Inventory with 
# the "--add" command line option.
#
# == Usage
# simHMI.rb
# 
# == Author
# Deimos-Space S.L. (bolf)
#
# == Copyright
# Copyright (c) 2007 ESA - Deimos Space S.L.
#

#########################################################################
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: addInterfaces2Database.rb,v 1.5 2007/02/06 13:38:56 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require 'cuc/Listener'

require 'ProcessHandler'

# Global variables
@@dateLastModification = "$Date: 2007/02/06 13:38:56 $"   # to keep control of the last modification
                                     # of this script
@@verboseMode     = 0                # execution in verbose mode
@@mnemonic        = ""
@@bShowMnemonics  = false
@@numProcesses    = 0
@@numScenes       = 0

# MAIN script function
def main
   @isDebugMode = false
   @commandNRTP = ""
   @sleepAgain  = true
   
   opts = GetoptLong.new(
     ["--command", "-c",        GetoptLong::REQUIRED_ARGUMENT],
     ["--Show", "-S",           GetoptLong::NO_ARGUMENT],
     ["--Verbose", "-V",        GetoptLong::NO_ARGUMENT],
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
     ["--scenes", "-s",         GetoptLong::REQUIRED_ARGUMENT],
     ["--processes", "-p",      GetoptLong::REQUIRED_ARGUMENT],
     ["--PID", "-P",            GetoptLong::REQUIRED_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Verbose"       then @@verboseMode = 1
            when "--Debug"         then @isDebugMode = true
            when "--version" then
               print("\nESA - Deimos-Space S.L.  DEC ", File.basename($0), " $Revision: 1.5 $  [", @@dateLastModification, "]\n\n\n")
               exit (0)
            when "--command" then
               @commandNRTP = arg.to_s        
            when "--processes" then
               @@numProcesses = arg.to_i
            when "--scenes"    then 
               @@numScenes    = arg.to_i
            when "--help"          then RDoc::usage
            when "--usage"         then RDoc::usage("usage")
            when "--Show"          then @@bShowMnemonics = true
         end
      end
   rescue Exception
      exit(99)
   end


   trap("USR2")   {  
                     # puts "[NRTP - HMI] Signal SIGUSR2 received ...\n"
                     
                     if File.exist?("NRTP_STATUS_SUCCESS") == true then
                        puts "NRTP Execution was successfull ! :-)"
                        puts "======================================="
                        File.delete("NRTP_STATUS_SUCCESS")
                        @sleepAgain = true
                     end

                     if File.exist?("NRTP_STATUS_FAILED") == true then
                        puts "NRTP Execution FAILED ! :-("
                        puts "======================================="
                        File.delete("NRTP_STATUS_FAILED")
                        @sleepAgain = true
                     end
                     
                     if File.exist?("NRTP_STATUS_ACK") == true then
                        puts "Message Acknowledge, keep on waiting ! ;-)"
                        File.delete("NRTP_STATUS_ACK")
                        @sleepAgain = true
                     end
                     
                  }

   Dir.chdir(ENV['NRTP_HMI_TMP'])
   puts
   puts "----------------------------------------------"
   puts "I am NRTP-HMI running with pid #{Process.pid}"
   puts "----------------------------------------------"
   puts
   
   while @sleepAgain
      sleep
   end
   
   puts
   puts "NRTP-HMI Bye"
       
   
end


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
