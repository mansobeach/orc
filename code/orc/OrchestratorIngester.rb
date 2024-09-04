#!/usr/bin/env ruby

#########################################################################
##
## === Ruby source for #OrchestratorIngester class
##
## === Written by DEIMOS Space S.L. (bolf)
##
## === ORC Component
## 
## Git: $Id: OrchestratorIngester.rb,v 1.7 2009/03/31 08:42:53 decdev Exp $
##
## module ORC
##
#########################################################################

require 'cuc/DirUtils'
require 'cuc/Log4rLoggerFactory'

require 'orc/ReadOrchestratorConfig'
require 'orc/ORC_DataModel'


module ORC


class OrchestratorIngester
   
   include CUC::DirUtils
   
   ## -----------------------------------------------------------
  
   ## Class constructor

   def initialize(pollDir, interval, debugMode, log, pid)
      @logger              = log
      @pollingDir          = pollDir
      @intervalSeconds     = interval
      @isDebugMode         = debugMode
      @observerPID         = pid
      @newFile             = false
      @ftReadConf          = ORC::ReadOrchestratorConfig.instance
      if @isDebugMode == true then
         @ftReadConf.setDebugMode
      end

      @orcTmpDir           = @ftReadConf.getTmpDir
      @parallelIngest      = @ftReadConf.getParallelIngest
      @archiveHandler      = @ftReadConf.getArchiveHandler
      
      if ENV['ORC_DB_ADAPTER'] == "sqlite3" then
         @parallelIngest      = 1
      end
      
      checkModuleIntegrity
      
      registerSignals
      
   end
   ## -----------------------------------------------------------

   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("OrchestratorIngester debug mode is on")
   end
   ## -------------------------------------------------------------

   def ingestFile(polledFile)
      bIngested   = false
      cmd         = "minArcFile -T #{@archiveHandler} -f #{polledFile} -t"         
      filetype    = `#{cmd}`.chop
      
      if @isDebugMode == true then
         @logger.debug("Extracting filetype for #{polledFile}")
         @logger.debug(%Q{#{cmd} / #{filetype} => #{$?}})
      end
                                 
      if @ftReadConf.isValidFileType?(polledFile) == true then
         @newFile = true
         
         cmd      = "minArcStore --noserver -t #{@archiveHandler} -m -f #{@pollingDir}/#{polledFile}"
         if @isDebugMode == true then
            cmd = "#{cmd.dup} -D"
         end
         retVal   = system(cmd)
         
         if @isDebugMode == true then
            @logger.debug("#{cmd} => #{$?}")
         end
         
         if retVal == true then
            @logger.info("[ORC_110] #{polledFile} archived")            
            bIngested = true
         else
            cmd = "minArcRetrieve --noserver -l -f #{File.basename(polledFile, ".*")}"
            retVal   = system(cmd)
            if @isDebugMode == true then
               @logger.debug("#{cmd} / #{retVal}")
            end
            if retVal == true then
               bIngested = true

               @logger.warn("[ORC_304] #{polledFile} polled is already in the archive")

               @triggerProd = TriggerProduct.find_by_filename(polledFile)
               if @triggerProd != nil then
                  @logger.warn("[ORC_303] #{polledFile} polled has been previously processed / it is discarded")
                  bIngested = false
               else
                  bIngested = true
               end

            else
               bIngested = false
               @logger.error("[ORC_611] #{polledFile} archiving failed")
            end
         end

         if bIngested == true then
            ## Queue in pending the trigger file-types
            if @ftReadConf.isFileTypeTrigger?(polledFile) == true then
               cmd      = "orcQueueInput -f #{polledFile} -P -s NRT"
               retVal   = system(cmd)
               if @isDebugMode == true then
                  @logger.debug("#{cmd} / #{retVal}")
               end
               if retVal != true then
                  @logger.error("[ORC_601] #{polledFile} pending queue failed")
                  cmd      = "minArcRetrieve --noserver -f #{File.basename(polledFile, ".*")} -L #{@ftReadConf.getFailureDir}"
                  retVal   = system(cmd)
                  if retVal == true then
                     @logger.info("#{polledFile} copied into failure dir #{@ftReadConf.getFailureDir}")
                  else
                     @logger.error("Could not place #{polledFile} into failure dir #{@ftReadConf.getFailureDir}")
                  end
                  return false
               else
                  @logger.info("[ORC_115] #{polledFile} queued in pending") 
               end
            else
               @logger.warn("[ORC_305] #{polledFile} / #{@ftReadConf.getDataType(polledFile)} is not trigger-type")
            end
         end  
      else
         bIngested = false
         @logger.error("[ORC_602] #{polledFile} #{filetype} filetype not configured")
      end
      
      ## ---------------------------------------------------
      ##   
      ## Move to ingestionError folder if still present in polling dir
      ##
      ## 1- not configured triggers to orc are moved 
      ## 2- theoretically minarc errors would move files into MINARC_ARCHIVE_ERROR
      
      if bIngested == false and File.exist?("#{@pollingDir}/#{polledFile}") == true then      
         command = "\\mv -f #{@pollingDir}/#{polledFile} #{@orcTmpDir}/_ingestionError"      
         if @isDebugMode == true then
            @logger.debug(%Q{\n#{command}})
         end
            
         retVal = system(command)          
            
         if retVal == true then
            @logger.warn("File #{polledFile} moved to #{@orcTmpDir}/_ingestionError")
         else
            @logger.warn("Failed to move #{polledFile} to #{@orcTmpDir}/_ingestionError")
            command = "\\rm -rf #{@pollingDir}/#{polledFile}"
            if @isDebugMode == true then
               @logger.debug(%Q{\n#{command}})
            end
            system(command)
         end               
      end
      
      ## ---------------------------------------------------   
         
      return bIngested
           
   end
   ## -------------------------------------------------------------

   ## Method that checks on the given array of files which one is a 
   ## valid type and stores or delete it accordingly to the result
   def ingest(arrPolledFiles)
      @newFile = false
      
      ## -----------------------------------------
      ## Log all files found in the polling dir
      arrPolledFiles.each{|polledFile|   
         @logger.info(%Q{[ORC_100] #{polledFile} found})
      }
      ## -----------------------------------------
      
      loop do
         
         break if arrPolledFiles.empty?
         
         1.upto(@parallelIngest) {|i|
         
            break if arrPolledFiles.empty?
            
            file = arrPolledFiles.shift

            if file.to_s.slice(0,1) == "_" or file.to_s.slice(0,1) == "." then
               @logger.warn(%Q{[ORC_301] Discarded #{file}})
               next
            end

#            if file.to_s.slice(0,1) == "_" or file.to_s.slice(0,2) != "S2" then
#               @logger.warn(%Q{[ORC_301] Discarded #{file}})
#               next
#            end
            
            fork{
            	ret = ingestFile(file)
               if ret == false then
                  exit(1)
               else
                  exit(0)
               end 
            }
         }
         arr = Process.waitall
         arr.each{|child|
            if child[1].exitstatus == 0 then
               @newFile = true
            else
               # @logger.error("Problem(s) during file ingestion")
            end
         }
      end

      ## ---------------------------------------------------
      ## Notify to the scheduler if a new file has been detected

      if (@observerPID != nil) and (@newFile == true) then
         sleep(2.0)
         @logger.info("[ORC_120] Loop completed")                            
         ret = Process.kill("SIGUSR1", @observerPID)
         @logger.info("[ORC_125] SIGUSR1 sent to Scheduler with pid #{@observerPID} / #{ret}")
      end
      ## ---------------------------------------------------
      
      @newFile = false   
  
   end
   ## -------------------------------------------------------------
   
   ## Method triggered by Listener 
   def poll
      startTime = Time.new
      startTime.utc 
      
      if @isDebugMode == true then
         @logger.debug("[ORC_XXX] Ingester is polling #{@pollingDir}")
      end     

      ## Polls the given dir and calls the "ingest" method for each entry
      prevDir = Dir.pwd     
      begin 
         Dir.chdir(@pollingDir) do
            d=Dir["*"]
            ## -------------------------
            ## main method to ingest every entry
            self.ingest(d)
            ## -------------------------
            if @isDebugMode == true then
               @logger.debug("[ORC_XXX] Ingester Successfully Polling #{@pollingDir}  !")
            end
         end      
      rescue SystemCallError => e
         @logger.error("Could not Poll #{@pollingDir}  !")
         @logger.error(e.to_s)
         @logger.error(e.backtrace)
      end    
      Dir.chdir(prevDir)

      # Calculate required time and new interval time.
      stopTime     = Time.new
      stopTime.utc   
      requiredTime = stopTime - startTime   
      nwIntSeconds = @intervalSeconds - requiredTime.to_i
   
      if @isDebugMode == true and nwIntSeconds > 0 then
         @logger.debug("Ingester New Trigger Interval is #{nwIntSeconds} seconds | #{@intervalSeconds} - #{requiredTime.to_i}")
      end
   
      if @isDebugMode == true and nwIntSeconds < 0 then
         @logger.debug("Time performed for polling is higher than interval Server !")
         @logger.debug("polling interval -> #{@intervalSeconds} seconds ")
         @logger.debug("time required    -> #{requiredTime.to_i} seconds ")
      end
      
      # The lowest time we return is one second. 
      # 0 would produce the process to sleep forever.
    
      if nwIntSeconds > 0 then
         return nwIntSeconds
      else
         return 1
      end   
   end
   ## -------------------------------------------------------------

private
  
   # -------------------------------------------------------------
   # Check that everything needed by the class is present.
   
   def checkModuleIntegrity
   
      bCheckOK = true
      bDefined = true
      
      checkDirectory("#{@orcTmpDir}/_ingestionError")


      if bCheckOK == false or bDefined == false then
         puts "OrchestratorIngester::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end

   end
   # -------------------------------------------------------------

   ## -----------------------------------------------------------

   def registerSignals
      if @isDebugMode == true then
         @logger.debug("OrchestratorIngester::registerSignals")
      end
      
      Signal.trap("SIGTERM") { 
                        signalHandler("sigterm")
                      }                                         
                       
   end
   ## -----------------------------------------------------------

   ## -----------------------------------------------------------

   def signalHandler(usr)
      puts "OrchestratorIngester::signalHandler=>#{usr}"
      ## --------------------------------
      
      ## --------------------------------
     
      if (usr == "sigterm") then
         bHandled = true
         puts "SIGTERM received / sayonara baby :-O"
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

end #end class

end #module
