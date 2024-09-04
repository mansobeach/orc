#!/usr/bin/env ruby

# == Synopsis
#
# This is an Orchestrator command line tool that polls incoming files.
#
# == Usage
# ingestorComponent.rb --polldir <full_path_dir> --interval <seconds>
#     --check               it checks whether the ingestorComponent is running
#     --stop                it stops the ingestorComponent.rb
#     --polldir <full_path_dir> (directory to be polled)
#     --interval            the frequency it is polled orchestrator in-tray (in seconds)
#     --help                shows this help
#     --Debug               shows Debug info during the execution
#     --version             shows version number      
# 
# == Author
# DEIMOS-Space S.L. (bolf)
#
# == Copyright
# Copyright (c) 2009 ESA - DEIMOS Space S.L.
#


#########################################################################
#
# === MDS-LEGOS -> Orchestrator
#
# CVS: $Id: ingestorComponent.rb,v 1.8 2008/07/03 11:38:07 decdev Exp $
#
#########################################################################





require 'getoptlong'
require 'rdoc/usage'



require 'orc/OrchestratorIngester'

require 'cuc/Listener'
require 'cuc/Log4rLoggerFactory'
require 'cuc/DirUtils'
require 'cuc/CheckerProcessUniqueness'
require 'cuc/CommandLauncher'
require 'ctc/ReadInterfaceConfig'
require 'dcc/ReadConfigDCC'




# Global variables
@@dateLastModification = "$Date: 2008/07/03 11:38:07 $"   


# MAIN script function
def main

   include CUC::DirUtils
   include CUC::CommandLauncher

   @isDebugMode        = false
   @bCheckIngestor     = false
   @pollingDir			  = ""
   @intervalSeconds    = 0
   
   bStop               = false
   
   opts = GetoptLong.new(        
      ["--polldir", "-p",	      GetoptLong::REQUIRED_ARGUMENT],
      ["--interval", "-i",       GetoptLong::REQUIRED_ARGUMENT],
      ["--stop", "-s",           GetoptLong::NO_ARGUMENT],
      ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
      ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],      
      ["--check", "-c",          GetoptLong::NO_ARGUMENT],
      ["--version", "-v",        GetoptLong::NO_ARGUMENT],
      ["--help", "-h",           GetoptLong::NO_ARGUMENT]
      )

   begin
      opts.each do |opt, arg|
         case opt      
	         when "--check"    then @bCheckIngestor = true
            when "--Debug"    then @isDebugMode = true
            
            when "--version"  then
               print("\nESA - DEIMOS-Space S.L.  ORC ", File.basename($0))
               print("    $Revision: 1.8 $\n  [", @@dateLastModification, "]\n\n\n")
               exit(0)            
	         when "--polldir" then
               @pollingDir = arg           
            when "--help"     then RDoc::usage
            when "--interval" then
               @intervalSeconds = arg.to_i
	         when "--stop"     then
               bStop = true       
            when "--usage"    then RDoc::usage("usage")
         end
      end
   rescue Exception
      exit(99)
   end 
   
   
   if @bCheckIngestor == true then
      checkIngestor
      exit(0)
   end
   

   # Check input parameters

   if (@intervalSeconds == 0 or @pollingDir == "") and bStop == false then
      RDoc::usage("usage")
   end
 
   # CheckModuleIntegrity
   checkModuleIntegrity  

   # initialize logger
   loggerFactory = CUC::Log4rLoggerFactory.new("ingestorComponent", "#{ENV['ORC_CONFIG']}/orchestrator_log_config.xml")
   
   if @isDebugMode then
      loggerFactory.setDebugMode
   end
      
   @logger = loggerFactory.getLogger
   
   if @logger == nil then
      puts
		puts "Error in OrchestratorIngester::initialize"
		puts "Could not initialize logging system !  :-("
      puts "Check ORC logs configuration under \"#{ENV['ORC_CONFIG']}/orchestrator_log_config.xml\"" 
	   puts
		puts
		exit(99)
   end

   if bStop == true then
      stopIngestor            
      exit(0)
   end

   @logger.info("Starting orchestrator ingestor daemon with frq #{@intervalSeconds} s")

   @projectName = DCC::ReadConfigDCC.instance.getProjectName
   @projectID   = DCC::ReadConfigDCC.instance.getProjectID
    
       
   @OrcIng = ORC::OrchestratorIngester.new(@pollingDir, @intervalSeconds, @isDebugMode, @logger) 
        
    # Create our lovely listener and start it.
      listener = CUC::Listener.new(File.basename($0), "", @intervalSeconds, @OrcIng.method("poll").to_proc)

      trap("SIGHUP") {  
                        puts "\nPolling requested for #{@pollingDir} ...\n"
                        @logger.info("Polling Requested for #{@pollingDir}")
                     }   

      if @isDebugMode == true
         listener.setDebugMode
      end
		   
      # start server
      listener.run
   
end
#-------------------------------------------------------------


# It stops the Orchestrator Ingestor 
   def stopIngestor
      checker = CUC::CheckerProcessUniqueness.new(File.basename($0), "", true)
      pid     = checker.getRunningPID

      if pid == false then
         puts "There was not a daemon for the IngestorComponent running !"
         @logger.info("Ingestor daemon was not running")
      else
         puts "Sending signal SIGKILL to Process #{pid} for killing IngestorComponent"
         @logger.info("Stopping orchestrator ingestor daemon")
         Process.kill(9, pid.to_i)
	      checker.release
      end
   end
#-------------------------------------------------------------

# It checks whether the Listener is running or not
   def checkIngestor   
       checker = CUC::CheckerProcessUniqueness.new(File.basename($0), "", true)

       if @isDebugMode == true then
          checker.setDebugMode
       end
       ret = checker.isRunning
       if ret == false then         
          puts "IngestorComponent daemon is not running !"            
       else
          puts "IngestorComponent daemon is running"          
       end
   end
#-------------------------------------------------------------

# Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true     
      if !ENV['DCC_TMP'] then
         puts "\nDCC_TMP environment variable not defined !\n"
         bDefined = false
      end
      if !ENV['ORC_CONFIG'] then
         puts "\nDCC_TMP environment variable not defined !\n"
         bDefined = false
      end      
      if bDefined == false then
         puts "\nError in ingestorComponent.rb::checkModuleIntegrity :-(\n\n"
         exit(99)
      end                             
   end
#-------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
