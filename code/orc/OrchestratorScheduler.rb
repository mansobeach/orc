#!/usr/bin/env ruby

#########################################################################
##
## === Ruby source for #OrchestratorScheduler class
##
## === Written by DEIMOS Space S.L. (bolf)
##
## === Orchestrator => ORC Component
## 
## Git: $Id: OrchestratorScheduler.rb,v 1.9 2009/04/30 11:58:52 decdev Exp $
##
## module ORC
##
#########################################################################

require 'cuc/Log4rLoggerFactory'

require 'orc/ReadOrchestratorConfig'
require 'orc/ORC_DataModel'
require 'orc/PriorityRulesSolver'

module ORC

class OrchestratorScheduler

   ## -------------------------------------------------------------
  
   ## Class constructor

   def initialize(log, debug)

      checkModuleIntegrity
            
      @logger           = log
      
      loggerFactory = CUC::Log4rLoggerFactory.new("Scheduler", "#{ENV['ORC_CONFIG']}/orchestrator_log_config.xml")
   
      if @isDebugMode then
         loggerFactory.setDebugMode
      end
      
      @logger = loggerFactory.getLogger   
      if @logger == nil then
         puts
		   puts "Error in OrchestratorIngester::initialize"
     	   puts "Could not initialize logging system !  :-("
         puts "Check ORC logs configuration under \"#{@orcConfigDir}/orchestrator_log_config.xml\"" 
 	      puts
   	   exit(99)
      end
      
      @bFirstSchedule      = true
      @isDebugMode         = debug
      @arrQueuedFiles      = Array.new
      @arrPendingFiles     = Array.new
      @sleepSigUsr2        = false
      @sig1flag            = false
      @bJobJustTriggered   = false
      @bProcRunning        = false

      ## --------------------------------
      ## Get Orchestrator Configuration
      @ftReadConf          = ORC::ReadOrchestratorConfig.instance
      @procWorkingDir      = @ftReadConf.getProcWorkingDir  
      @successDir          = @ftReadConf.getSuccessDir
      @failureDir          = @ftReadConf.getFailureDir   
      @freqScheduling      = @ftReadConf.getSchedulingFreq.to_f
      @resourceManager     = @ftReadConf.getResourceManager
      @orcTmpDir           = @ftReadConf.getTmpDir
      # --------------------------------

      @bExit              = false
      @sigUsr1Received    = false
      @sigUsr1Count       = 0
      
      registerSignals
   end
   ## -----------------------------------------------------------

   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("OrchestratorScheduler debug mode is on")
   end
   ## -----------------------------------------------------------   

   ## Get all Queued Files
   def loadQueue
      if @isDebugMode == true then
         msg = "OrchestratorScheduler::loadQueue begin"
         @logger.debug(msg)
      end
      
#      if @isDebugMode == true then
#         puts "Scheduler PAUSED / press any key"
#         STDIN.getc
#      end
      
      HandleDBConnection.new      
      
      ## https://jira.elecnor-deimos.com/browse/S2MPASUP-402
      # @arrQueuedFiles = OrchestratorQueue.getQueuedFiles
      @arrQueuedFiles = OrchestratorQueue.all
      
      if @isDebugMode == true then
         @arrQueuedFiles.each{|item|
            @logger.debug("load queue in memory : #{item.filename}")
         }
      end
      
      if @isDebugMode == true then
         msg = "OrchestratorScheduler::loadQueue completed"
         @logger.debug(msg)
      end
   end
   ## -----------------------------------------------------------  

   ## This method gets all files referenced in Pending2QueueFile
   ## table and adds them to Orchestrator_Queue table
   def enqueuePendingFiles_BULK

      if @isDebugMode == true then
         msg = "OrchestratorScheduler::enqueuePendingFiles begin"
         @logger.debug(msg) 
      end
      
      @arrPendingFiles = Pending2QueueFile.getPendingFiles     

      if @arrPendingFiles.empty? == true then
         msg = "No new input files are pending to be queued"
         # puts msg
         @logger.debug(msg)
         return
      end
      
      cmd = "orcQueueInput --Bulk"          
      @logger.debug("#{cmd}")
                  
      ret = system(cmd)
         
      if ret == false then
         @logger.error("Could not queue PENDING files")
      end
   end
   
   ## -------------------------------------------------------------
   
   ## -----------------------------------------------------------  

   ## This method gets all files referenced in Pending2QueueFile
   ## table and adds them to Orchestrator_Queue table
   def enqueuePendingFiles
      if @isDebugMode == true then
         msg = "OrchestratorScheduler::enqueuePendingFiles begin"
         @logger.debug(msg) 
      end

      @arrPendingFiles = Pending2QueueFile.all  

      if @arrPendingFiles.empty? == true then
         if @isDebugMode == true then
            msg = "No new input files are pending to be queued"
            @logger.debug(msg)
         end
         return
      end
      
      arrIds = Array.new
  
      OrchestratorQueue.transaction do
         @arrPendingFiles.each{|file|
            new_queued_file = OrchestratorQueue.new
            new_queued_file.trigger_product_id  = file.trigger_product_id
            new_queued_file.filename            = file.filename
            new_queued_file.filetype            = file.filetype
            new_queued_file.queue_date          = Time.now
            new_queued_file.save
            @logger.info("[ORC_215] #{file.filename} queued for dispatch")
            Pending2QueueFile.destroy_by(trigger_product_id: file.trigger_product_id)  
         }
      end

      if @isDebugMode == true then
         msg = "OrchestratorScheduler::enqueuePendingFiles end"
         @logger.debug(msg) 
      end
         
   end
   
   ## -------------------------------------------------------------
   
   def schedule
      if @isDebugMode == true then
         msg = "[ORC_XXX] Orchestrator::schedule started"
         @logger.debug(msg)
      end
      @sigUsr1Received = false
      while true do
         @logger.info("[ORC_200] Load queue for dispatch")
         loadQueue
         @logger.info("[ORC_205] Dispatching jobs")
         dispatch
         @logger.info("[ORC_210] Queue pending triggers into dispatch")
         enqueuePendingFiles
         # @logger.info("[ORC_220] Queue pending into dispatch")
         if @arrPendingFiles.empty? == true and @sigUsr1Received == false then
            @logger.info("[ORC_225] Waiting for new inputs / enabling SIGUSR1 / #{@sigUsr1Count}")
            sleep 10.0 until @sigUsr1Received
         end
         @sigUsr1Received = false
      end
   end
   ## -------------------------------------------------------------

   ## -----------------------------------------------------------

   ## This method will implement Processing Rule Priorities.
   ## It will sort @arrQueuedFiles object to trigger pending jobs
   ## sorted by priority
   def sortPendingJobs
      
      if @isDebugMode == true then
         msg = "OrchestratorScheduler::Sorting Pending jobs / PriorityRulesSolver"
         @logger.debug(msg)
      end
      
      resolver = ORC::PriorityRulesSolver.new(@logger)
      
      if @isDebugMode == true then
         resolver.setDebugMode
      end
      
      @arrQueuedFiles = Array.new
      
      begin
         @arrQueuedFiles = resolver.getSortedQueue
      rescue Exception => e
         @logger.error("[ORC_999] FATAL ERROR: #{e.to_s}")
         if @isDebugMode == true then
            @logger.debug(e.backtrace)
         end
         exit(127)
      end
         
      i = 1
      
      @arrQueuedFiles.each{|queuedFile|
         @logger.debug("[#{i.to_s.rjust(2)}] - #{queuedFile.id.to_s.rjust(4)}   #{queuedFile.filename}")
         i = i + 1
      }
      return
   end
   ## -----------------------------------------------------------

   ## It removes from execution current job
   def abortCurrentJob
      cmd = "#{@helperExecutable} -c abort"
      @logger.debug("\n#{cmd}")
      system(cmd)
      @logger.debug("Aborting current job #{@currentTrigger.filename}")
      sleep(5)
   end
   ## -----------------------------------------------------------
   
   def triggerJob(selectedQueuedFile)
      @bJobJustTriggered = true
      
      @logger.info("[ORC_240] Triggering Job => #{selectedQueuedFile.filename}")
      
      cmd = ""
      if selectedQueuedFile.filename.include?(".TGZ") == true then      
         cmd = "minArcRetrieve --noserver -f #{selectedQueuedFile.filename} -L #{@procWorkingDir} -H"
      else
         cmd = "minArcRetrieve --noserver -f #{selectedQueuedFile.filename} -L #{@procWorkingDir} -H -U"
      end

      if @isDebugMode == true then
         @logger.debug(cmd)
      end
 
      ret = system(cmd)

      if ret == false then
         @logger.error("[ORC_612] #{selectedQueuedFile.filename} retrieval failed")
      end
     
      dataType = @ftReadConf.getDataType(selectedQueuedFile.filename)
      ##dataType = @ftReadConf.getDataType(selectedQueuedFile.filetype)
      
      if dataType == nil then
         msg = "[ORC_705] Configuration failure => could not find datatype for filetype #{selectedQueuedFile.filetype}"
         @logger.error(msg)
         raise msg
      end
      
      procCmd  = @ftReadConf.getExecutable(dataType)
      
      if procCmd == nil then
         msg = "[ORC_705] Configuration failure => could not find ProcessingRule executable for #{dataType}"
         @logger.error(msg)
         raise msg
      end
      
      procCmd  = procCmd.gsub("%F", "#{@procWorkingDir}/#{selectedQueuedFile.filename}")
      
      if @isDebugMode == true then
         @logger.debug(procCmd)
      end
      
      # --------------------------------
      # TRIGGER PROCESSOR !!  :-)
  
      retVal = system(procCmd)
      
      # fork { exec(cmd) }
      # --------------------------------
   
      # # Update Trigger status with SUCCESS
      # retVal = true

      if retVal == true then
         @logger.info("[ORC_250] #{selectedQueuedFile.filename} job successful")
         cmd = "orcQueueUpdate -f #{selectedQueuedFile.filename} -s SUCCESS"
         if @isDebugMode == true then
            @logger.debug(cmd)
         end
         retVal = system(cmd)
         if retVal == false then
            @logger.error("Failed exec of #{cmd}")
         end
      else
         @logger.error("[ORC_666] #{selectedQueuedFile.filename} job failed / #{procCmd}")
         cmd = "orcQueueUpdate -f #{selectedQueuedFile.filename} -s FAILURE"
         if @isDebugMode == true then
            @logger.debug(cmd)
         end
         retVal = system(cmd)
         if retVal == false then
            @logger.error("Failed exec of #{cmd}")
         end
      end
   
      # sleep(@freqScheduling)
   
   end
   ## -------------------------------------------------------------

   ## -------------------------------------------------------------
   ##
   ## Method in charge of dispatching new jobs
   def dispatch
   
      msg = "OrchestratorScheduler::dispatch => Dispatching new job(s)"
      
      if @isDebugMode == true then
         @logger.debug(msg)
      end
      
      @procWorkingdir   = ""
      inputsDir         = ""

      # --------------------------------
      
      # Scheduler sorting algorithm
      sortPendingJobs
      
      # --------------------------------
      # Trigger Jobs
      
      while !@arrQueuedFiles.empty? do

         jobfile = @arrQueuedFiles.shift
         begin
            triggerJob(jobfile)
         rescue Exception => e
            ## job failure due to unexpected error
            ## need to enforce that file is classified as failure
            @logger.error("[ORC_666] #{jobfile.filename} job failed")
            cmd = "orcQueueUpdate -f #{jobfile.filename} -s FAILURE"
            if @isDebugMode == true then
               @logger.debug(cmd)
            end
            retVal = system(cmd)
            if retVal == false then
               @logger.error("Failed exec of #{cmd}")
            end
         end

         cmd = "#{@resourceManager}"
         
         retVal = system(cmd)
         
         while (retVal == false) do
            @logger.info("[ORC_230] No resources available / queue length: #{@arrQueuedFiles.length} / sleeping #{@freqScheduling} s")
            sleep(@freqScheduling)
            retVal = system(cmd)
         end         
      end
   end
   ## -------------------------------------------------------------



private

	## -------------------------------------------------------------
   ##
   ## Check that everything needed by the class is present.
   def checkModuleIntegrity
   
      bCheckOK = true
      
      if bCheckOK == false then
         puts "OrchestratorScheduler::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end

   end
   ## -----------------------------------------------------------

   ## This method loads from database queued files
   def getQueuedFiles 
      return OrchestratorQueue.getQueuedFiles
   end
   ## -----------------------------------------------------------

   def getFilesToBeQueued
      return Pending2QueueFile.getPendingFiles
   end
   ## -----------------------------------------------------------

   ## -----------------------------------------------------------

   def registerSignals
      if @isDebugMode == true then
         @logger.debug("OrchestratorScheduler::registerSignals")
      end
      
      Signal.trap("SIGTERM") { 
                        signalHandler("sigterm")
                      }                                         


      Signal.trap("SIGUSR1") {                          
                        signalHandler("usr1")               
                      }     

      Signal.trap("SIGUSR2") { 
                        signalHandler("usr2")
                      }                                         
                       
      Signal.trap("SIGHUP")  {
                        signalHandler("sighup")
                      }
   end
   ## -----------------------------------------------------------

   ## -----------------------------------------------------------

   def signalHandler(usr)
      puts
      puts "OrchestratorScheduler::signalHandler=>#{usr}"
      puts
      ## --------------------------------
      
      if (usr == "usr1") then
         @sigUsr1Received = true
         @sigUsr1Count    = @sigUsr1Count + 1
      end

      ## --------------------------------
     
      if (usr == "sigterm") then
         bHandled = true
         puts
         puts "SIGTERM received / sayonara baby :-O"
         puts
         exit(0)
      end

      ## --------------------------------
      ## Unhandled Signal
      if bHandled == false then
         puts "Signal #{usr} not managed"
      end
      ## --------------------------------

   end
   ## -------------------------------------------------------------


end # class

end # module
