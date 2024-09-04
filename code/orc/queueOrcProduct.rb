#!/usr/bin/env ruby

# == Synopsis
#
# This is an NRTP Orchestrator command line tool used to queue a trigger product for NRTP processing.
# This tool will only queue files that follow the Earth-Explorer naming standard. 
#
# 
# -f flag:
#
# Mandatory flag. This option is used to specify the name of the file to be queued.  
#
#
# -s flag:
#
# Mandatory flag. This flag is used to specify the status of the file in the queue.
# Expected values are :
# NRT
# MIXED
# OLD
# OBSOLETE
#
#
# -l flag:
#
# This option is used to list queued trigger products in the standard output.
# Additional flags shall be specified to determine the list of desired trigger products.
# -Q flag - Queued Trigger Products
# -O flag - Obsolete Trigger Products
# -S flag - Successful Trigger Products
# -F flag - Failed Trigger Products 
#
#
# -R flag:
#
# This flag is used with -l flag. It receives with a full_path_filename and it writes the list 
# of files queued.
#
#
# -d flag:
#
# This is the delete flag. It deletes from the processing queue the specified file.
#  
#
# == Usage
# queueOrcProduct.rb -f <file-name> -s <file-status> | -l --Report <full_path_report_file>
#     --file <file-name>         it specifies the name of the file to be queued
#     --status                   it specifies the initial file-status of the file to be queued
#                                possible status are  NRT | MIXED | OLD | OBSOLETE
#     --list                     it shows the trigger files list. See flags below
#     --Queued                   it shows Queued Trigger Products
#     --Obsolete                 it shows Obsolete Trigger Products
#     --Success                  it shows Successful Trigger Products
#     --Failed                   it shows Failed Trigger Products
# 
#     --Report  <reportname>     it writes the list of trigger files queued into a report
#     --delete  <filename>       it deletes from the processing queue the specified file
#     --help                     shows this help
#     --usage                    shows the usage
#     --Debug                    shows Debug info during the execution
#     --version                  shows version number
# 
#
# == Author
# DEIMOS-Space S.L.
#
# == Copyright
# Copyright (c) 2008 ESA - DEIMOS Space S.L.
#

#########################################################################
#
# === SMOS NRTP Orchestrator
#
# CVS: $Id: queueOrcProduct.rb,v 1.12 2008/08/01 14:55:57 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require "cuc/EE_ReadFileName"
require "orc/ORC_DataModel"
require "orc/ReportQueuedFiles"

# Global variables
@@dateLastModification = "$Date: 2008/08/01 14:55:57 $"   # to keep control of the last modification
                                       # of this script
                                       # execution showing Debug Info


# MAIN script function
def main

   @bList                  = false

   #Hardcoded values
   @arrStatus = ["NRT", "MIX", "OLD", "OBS"]

   # Data provided by the user
   @filename               = ""
   @reportfilename         = ""
   @initialStatus          = "UKN"
   @bDelete                = false
   @isDebugMode            = false
   @bObsolete              = false
   @bQueued                = false
   @bSuccess               = false
   @bFailed                = false
   @bTrigger               = false

   # Data generated or extracted from filename
   @filetype               = ""
   @sensing_start          = nil
   @sensing_stop           = nil

   # Other required Data
   @detectionDate          = nil
   @runtime_satus          = "UKN"
   
   opts = GetoptLong.new(
     ["--file", "-f",            GetoptLong::REQUIRED_ARGUMENT],
     ["--status", "-s",          GetoptLong::REQUIRED_ARGUMENT],
     ["--Report", "-R",          GetoptLong::REQUIRED_ARGUMENT],
     ["--delete", "-d",          GetoptLong::REQUIRED_ARGUMENT],
     ["--Queued", "-Q",          GetoptLong::NO_ARGUMENT],
     ["--Success", "-S",         GetoptLong::NO_ARGUMENT],
     ["--Failed",  "-F",         GetoptLong::NO_ARGUMENT],
     ["--Obsolete", "-O",        GetoptLong::NO_ARGUMENT],
     ["--Trigger", "-T",         GetoptLong::NO_ARGUMENT],
     ["--Debug", "-D",           GetoptLong::NO_ARGUMENT],
     ["--list", "-l",            GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",           GetoptLong::NO_ARGUMENT],
     ["--version", "-v",         GetoptLong::NO_ARGUMENT],
     ["--help", "-h",            GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"     then @isDebugMode = true
            when "--version" then	    
               print("\nESA - DEIMOS-Space S.L. ", File.basename($0), " $Revision: 1.12 $  [", @@dateLastModification, "]\n\n\n")
               exit(0)
	         when "--file"          then @filename            =  File.basename(arg.to_s)
                                        @bIngest             = true
            when "--delete"        then @filename            =  File.basename(arg.to_s)
                                        @bDelete             = true
            when "--Report"        then @reportfilename      =  arg.to_s
            when "--list"          then @bList               =  true
            when "--Obsolete"      then @bObsolete           =  true
            when "--Queued"        then @bQueued             =  true
            when "--Trigger"       then @bTrigger            =  true
            when "--Success"       then @bSuccess            =  true
            when "--Failed"        then @bFailed             =  true
            when "--status"        then @initialStatus       = (arg.to_s).upcase[0..2]
			   when "--help"          then RDoc::usage
	         when "--usage"         then RDoc::usage("usage")
         end
      end
   rescue Exception
      exit(99)
   end

   ######################## Coherency Checks & Data Extraction ########################
   
   if @bDelete == true and @bIngest == true then
      puts
      RDoc::usage("usage")
      puts
      exit(99)
   end

   if @bDelete == true and @bList == true then
      puts
      RDoc::usage("usage")
      puts
      exit(99)
   end

   if @filename != "" and @bList == true
      puts
      RDoc::usage("usage")
      puts
      exit(99)
   end

   if @filename != "" and @bList == true then
      puts
      RDoc::usage("usage")
      puts
      exit(99)
   end

   if @reportfilename != "" and @filename != "" then
      puts
      RDoc::usage("usage")
      puts
      exit(99)
   end

   if @reportfilename != "" and @bList == false then
      puts
      RDoc::usage("usage")
      puts
      exit(99)
   end

   if (@filename == "" or @filename.length > 100) and @bList == false and @reportfilename == "" then
      puts
      puts
      RDoc::usage("usage")
      puts
      exit(99)
   end

   #----------------------------------------------
   # if just list the files queued
   
   if @bDelete == true then
      deleteFile
      exit(0)
   end
   #----------------------------------------------
   # if just list the files queued
   
   if @bList == true and @reportfilename == "" then
      list
      exit(0)
   end
   #----------------------------------------------
   # Generate the report

   if @bList == true and @reportfilename != "" then
      generateReport
      exit(0)
   end
   #----------------------------------------------


   nameDecoder = CUC::EE_ReadFileName.new(@filename)

   if nameDecoder.isEarthExplorerFile? == false then
      puts nameDecoder.fileType
      puts
      puts "\"#{@filename}\" is not a valid Earth-Explorer filename :-("
      puts
      exit(99)
   end

   @filetype = nameDecoder.fileType

   if @filetype == nil or @filetype == "" then
      puts
      puts "Could not identify EE file-type for #{@filename} :-("
      puts
      exit(99)
   end

   @sensing_start = nameDecoder.start_as_dateTime

   @sensing_stop  = nameDecoder.stop_as_dateTime

   @detectionDate = Time.now()

   if @arrStatus.include?(@initialStatus) == false then
      puts
      puts "Status \"#{@initialStatus}\" is not a valid status :-("
      puts
      RDoc::usage("usage")
      puts=
      exit(99)
   end

   ################################ Database insertion ################################
   TriggerProduct.transaction do
      # Trigger Product registration :
      newProd = TriggerProduct.new(:filename => @filename,
                                   :filetype => @filetype, 
                                   :detection_date => @detectionDate,
                                   :sensing_start => @sensing_start,
                                   :sensing_stop => @sensing_stop,
                                   :runtime_status => "UKN",
                                   :initial_status => @initialStatus)

      begin
         newProd.save!
      rescue Exception => e
         puts
         puts e.to_s
         puts
         puts " queue #{@filename} :-("
         puts
         puts
         exit(99)
      end

     if @initialStatus == "OBS" then
         newQueuedProd = ObsoleteTriggerProduct.new
         newQueuedProd.trigger_products = newProd
         newQueuedProd.obsolete_date      = @detectionDate
      else
         newQueuedProd = OrchestratorQueue.new
         newQueuedProd.trigger_products = newProd
      end

      begin
         newQueuedProd.save!
      rescue
         #unregistering the trigger product
         newProd.destroy

         puts
         puts "Unable to queue #{@filename} :-("
         puts "The file will be removed from the trigger products list..."
         puts
         exit(99)
      end

      puts
      puts "The file #{@filename} has been successfully registered and queued as a trigger product :-)" 
      puts  
   end
end

#-------------------------------------------------------------

# It provides the list of trigger-files to be processed [queued]
def list

   triggerFiles   = TriggerProduct.find(:all)

   if @bQueued == true then
      puts
      print "QUEUE_DATE------FILENAME-------------------------------------------------------STATUS", "\n"

      listFiles = OrchestratorQueue::getQueuedFiles

      listFiles.each{|triggerFile|
         print triggerFile.detection_date.strftime("%Y%m%dT%H%M%S "), 
                          triggerFile.filename.slice(0..59).ljust(63), triggerFile.initial_status.ljust(6), "\n"
      }
      puts
   end

   if @bObsolete == true then
      print "OBSOLETE_DATE---FILENAME------------------------------------------------------", "\n"

      obsoleteFiles  = ObsoleteTriggerProduct.find(:all)

      triggerFiles.each{|triggerFile|
         obsoleteFiles.each{|obsFile|
            if triggerFile.id == obsFile.trigger_product_id then
               print obsFile.obsolete_date.strftime("%Y%m%dT%H%M%S "),
                          triggerFile.filename, "\n"              
            end
         }         
      }
      puts
   end

   if @bSuccess == true then
      print "SUCCESS_DATE----FILENAME------------------------------------------------------", "\n"

      successFiles  = SuccessfulTriggerProduct.find(:all,
                                 :order => "success_date")
      successFiles.each{|sucFile|
         triggerFiles.each{|triggerFile|
            if triggerFile.id == sucFile.trigger_product_id then
               if sucFile.success_date != nil then
                  print sucFile.success_date.strftime("%Y%m%dT%H%M%S ")
               else
                  print "                "
               end
               print triggerFile.filename, "\n"
            end
         }         
      }
      puts
   end

   if @bFailed == true then
      print "FAILURE_DATE----FILENAME------------------------------------------------------", "\n"

      failureFiles  = FailingTriggerProduct.find(:all,
                                    :order => "failure_date")
      failureFiles.each{|obsFile|
         triggerFiles.each{|triggerFile|
            if triggerFile.id == obsFile.trigger_product_id then
               if obsFile.failure_date != nil then
                  print obsFile.failure_date.strftime("%Y%m%dT%H%M%S ")
               else
                  print "                "
               end
               print triggerFile.filename, "\n"
            end
         }         
      }
      puts
   end


   if @bTrigger == true then
      print "DETECTION_DATE--FILENAME------------------------------------------------------", "\n"
      
      triggerFiles.each{|triggerFile|            
         if triggerFile.detection_date != nil then
            print triggerFile.detection_date.strftime("%Y%m%dT%H%M%S ")
         else
            print "                "
         end
         print triggerFile.filename, "\n"
      }
   end

end
#-------------------------------------------------------------

# It provides the list of trigger-files to be processed [queued]
def generateReport

   listFiles      = OrchestratorQueue::getQueuedFiles

   writer = ORC::ReportQueuedFiles.new(@reportfilename)

   writer.write(listFiles)

end
#-------------------------------------------------------------

def deleteFile
   theFilename = File.basename(@filename)

   trgFile = TriggerProduct.find_by_filename(theFilename)

   if trgFile == nil then
      puts
      puts "#{theFilename} is not registered in the orchestrator"
      return
   end

   orcFile = OrchestratorQueue.find_by_trigger_product_id(trgFile.id)

   if orcFile != nil then
      begin
         orcFile.destroy
         puts "#{theFilename} removed from Orchestrator Queue"
      rescue Exception => e
         puts e.to_s
         puts "Could not delete #{theFilename} from Orchestrator Queue :-("
      end
   end

   orcFile = FailingTriggerProduct.find_by_trigger_product_id(trgFile.id)

   if orcFile != nil then
      begin
         orcFile.destroy
         puts "#{theFilename} removed from Orchestrator Failed Triggers"
      rescue Exception => e
         puts "Could not delete #{theFilename} from Orchestrator Failed Triggers :-("
      end
   end

   orcFile = SuccessfulTriggerProduct.find_by_trigger_product_id(trgFile.id)

   if orcFile != nil then
      begin
         orcFile.destroy
         puts "#{theFilename} removed from Orchestrator Successful Triggers"
      rescue Exception => e
         puts "Could not delete #{theFilename} from Orchestrator Successful Triggers :-("
      end
   end

   orcFile = ObsoleteTriggerProduct.find_by_trigger_product_id(trgFile.id)

   if orcFile != nil then
      begin
         orcFile.destroy
         puts "#{theFilename} removed from Orchestrator Obsolete Triggers"
      rescue Exception => e
         puts "Could not delete #{theFilename} from Orchestrator Obsolete Triggers :-("
      end
   end

   orcFile = TriggerProduct.find_by_id(trgFile.id)

   if orcFile != nil then
      begin
         orcFile.destroy
         puts "#{theFilename} removed from Orchestrator TriggerProducts table"
      rescue Exception => e
         puts "Could not delete #{theFilename} from TriggerProducts table :-("
      end
   end

end
#-------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
