#!/usr/bin/env ruby

# == Synopsis
#
# This is the NRTP Processor command line tool handler.
#
#
# == Usage
# nrtp_launcher.rb  --processes <np> --scenes <ns> | --command <cmd>  [--PID <pid>] [-L <log-file>]
#   --processes <np>     number of processes
#   --PID <pid>          Observer process PID
#   --Host               open-mpi host file 
#   --Log <log file>     full path of the log file
#   --Show               it shows all I/Fs already loaded in the DCC Inventory
#   --Verbose            execution in verbose mode
#   --version            shows version number
#   --help      shows this help
#   --usage     shows the usage
# 
# == Author
# Deimos-Space S.L. (bolf)
#
# == Copyright
# Copyright (c) 2007 ESA - Deimos Space S.L.
#

#########################################################################
#
# === Near Real Time Processor -> NRTP
# 
# CVS: $Id: nrtp_launcher.rb,v 1.5 2007/02/06 13:38:56 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require 'cuc/Listener'
require 'cuc/Log4rLogger'

require 'ProcessHandler'

# Global variables
@@dateLastModification = "$Date: 2007/02/06 13:38:56 $"   # to keep control of the last modification
                                     # of this script
@@verboseMode     = 0                # execution in verbose mode
@@mnemonic        = ""
@@bShowMnemonics  = false
@@numProcesses    = 0
@@numScenes       = 0
@@targetPID       = 0

# MAIN script function
def main
   @isDebugMode = false
   @commandNRTP = ""
   @hostFile    = ""
   @logFilePath = ""
   
   opts = GetoptLong.new(
     ["--command",    "-c",      GetoptLong::REQUIRED_ARGUMENT],
     ["--Show",       "-S",      GetoptLong::NO_ARGUMENT],
     ["--Verbose",    "-V",      GetoptLong::NO_ARGUMENT],
     ["--Debug",      "-D",      GetoptLong::NO_ARGUMENT],
     ["--version",    "-v",      GetoptLong::NO_ARGUMENT],
     ["--help",       "-h",      GetoptLong::NO_ARGUMENT],
     ["--usage",      "-u",      GetoptLong::NO_ARGUMENT],
     ["--scenes",     "-s",      GetoptLong::REQUIRED_ARGUMENT],
     ["--processes",  "-p",      GetoptLong::REQUIRED_ARGUMENT],
     ["--Host",       "-H",      GetoptLong::REQUIRED_ARGUMENT],
     ["--Log",        "-L",      GetoptLong::REQUIRED_ARGUMENT],
     ["--PID",        "-P",      GetoptLong::REQUIRED_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Verbose"       then @@verboseMode = 1
            when "--Debug"         then @isDebugMode = true

            when "--version" then
               print("\nESA - Deimos-Space S.L.  ", File.basename($0), " $Revision: 1.5 $  [", @@dateLastModification, "]\n\n\n")
               exit (0)

            when "--command"       then @commandNRTP = arg.to_s        
            when "--processes"     then @@numProcesses = arg.to_i
            when "--PID"           then @@targetPID = arg.to_i
            when "--Log"           then @logFilePath = arg.to_s
            when "--scenes"        then @@numScenes    = arg.to_i
            when "--Host"          then @hostFile = arg.to_s
            when "--help"          then RDoc::usage
            when "--usage"         then RDoc::usage("usage")
            when "--Show"          then @@bShowMnemonics = true
         end
      end
   rescue Exception
      exit(99)
   end


   if @hostFile != "" and @@numProcesses != 0 then  RDoc::usage end

   if @@numProcesses==0 and @hostFile == "" and @commandNRTP == "" then RDoc::usage end

   if @logFilePath != "" then
      logFactory = CUC::Log4rLogger.new("NRTP_Launcher")
      @logger = logFactory.setupManual(@logFilePath, false, false)
   end
   
   cmd = ""
   
   if @@numProcesses != 0 then
      cmd = "mpirun -np #{@@numProcesses} omp_mpi"
   else
      cmd = "mpirun --hostfile #{@hostFile} omp_mpi"
   end
      
   # Pass number of scenes to be processed
   if @@numScenes != 0 then
      cmd = "#{cmd} -s #{@@numScenes}"
   end
   
   if @isDebugMode == true then
      cmd = "#{cmd} -D"
   end
      
   @pHandler = NRTProcessHandler.new("nrtp_launcher.rb", cmd, @@targetPID)

   @logger.info("Launching NRTProcessHandler for PID : #{@@targetPID}")
   @logger.info("Cmd = #{cmd}")

   if @isDebugMode == true then
      @pHandler.setDebugMode
   end
   
   if @commandNRTP != "" then
      @logger.info("Processing command : #{@commandNRTP}")
      processCommand
      exit
   end

   @logger.info("Starting NRTP...")   
   ret = @pHandler.run
      
   if ret == false then
      puts "NRTP is already running"
      logger.warn("NRTP was already running !")
      exit(0)
   else
      puts
      puts "NRTP Execution ended"
      puts
      puts "Bye ! ;-)"
      puts
   end
   
end

def processCommand
   cmd = @commandNRTP
   case cmd.downcase
      when "quit"        then processCmdQuit
      when "resume"      then processCmdResume
      when "stop"        then processCmdStop
      when "status"      then processCmdStatus
      when "abort"       then processCmdAbort
      when "pause"       then processCmdPause
      when "help"        then processCmdHelp
   else
      puts "Ilegal command #{cmd} ! :-("
      @logger.error("Ilegal command #{cmd} !")
      exit(99)
   end
   exit(0)
end
#===============================================================================

def processCmdQuit
   puts "Quitting ..."
   @logger.info("Quitting ...")
   ret = @pHandler.quit
   if ret == false then
      puts "ERROR while quitting ..."
      @logger.error("ERROR while quitting ...")
   end
end

#===============================================================================

def processCmdAbort
   puts "Aborting ..."
   @logger.info("Aborting ...")
   ret = @pHandler.abort
   if ret == false then
      puts "ERROR while aborting ..."
      @logger.error("ERROR while aborting ...")
   end
end

#===============================================================================

def processCmdPause
   puts "Pausing ..."
   @logger.info("Pausing ...")
   @pHandler.pause
end

#===============================================================================


def processCmdResume
   puts "Resuming ..."
   @logger.info("Resuming ...")
   @pHandler.resume
end

#===============================================================================

def processCmdStop
   puts "Stopping ..."
   @logger.info("Stopping ...")
   @pHandler.stop
end

#===============================================================================

def processCmdStatus
   ret = @pHandler.status
   if ret == true then
      puts "NRTP is running"
      @logger.info("NRTP Status request : RUNNING")
   else
      puts "NRTP is not running"
      @logger.info("NRTP Status request : NOT RUNNING")
   end
end

#===============================================================================

def processCmdHelp
   puts "abort  -> it aborts nrtp generation"
   puts "help   -> it prints this help"
   puts "pause  -> it pauses NRTP execution"
   puts "resume -> it resumes NRTP execution"
   puts "quit   -> it quits NRTP"
   puts "status -> it checks whether NRTP is running"
   puts "stop   -> it finishes generation on a sync point"
end

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
