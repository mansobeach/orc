#!/usr/bin/env ruby

#########################################################################
##
## === Ruby source for #ORC_DatabaseModel class
##
## === Written by DEIMOS Space S.L. (bolf)
##
## === ORC Component
## 
## Git: $Id: ORC_DataModel.rb,v 1.14 2009/03/18 11:15:49 decdev Exp $
##
## module ORC
##
#########################################################################

require 'rubygems'
require 'active_record'

dbAdapter   = ENV['ORC_DB_ADAPTER']
dbHost      = ENV['ORC_DATABASE_HOST']
dbPort      = ENV['ORC_DATABASE_PORT']
dbName      = ENV['ORC_DATABASE_NAME']
dbUser      = ENV['ORC_DATABASE_USER']
dbPass      = ENV['ORC_DATABASE_PASSWORD']

ActiveRecord::Base.establish_connection(
                                          :adapter    => dbAdapter,
                                          :host       => dbHost,
                                          :port       => dbPort,
                                          :database   => dbName,
                                          :username   => dbUser, 
                                          :password   => dbPass, 
                                          :timeout    => 100000,
                                          :cast       => false,
                                          :pool       => 30
                                          )
                                          
## =====================================================================

class HandleDBConnection

   def initialize
      dbAdapter   = ENV['ORC_DB_ADAPTER']
      dbHost      = ENV['ORC_DATABASE_HOST']
      dbPort      = ENV['ORC_DATABASE_PORT']
      dbName      = ENV['ORC_DATABASE_NAME']
      dbUser      = ENV['ORC_DATABASE_USER']
      dbPass      = ENV['ORC_DATABASE_PASSWORD']

   ###   ActiveRecord::Base.clear_active_connections! ###

      ActiveRecord::Base.connection.close

      ActiveRecord::Base.connection.disconnect!

      ActiveRecord::Base.establish_connection(
                                          :adapter    => dbAdapter,
                                          :host       => dbHost,
                                          :port       => dbPort,
                                          :database   => dbName,
                                          :username   => dbUser, 
                                          :password   => dbPass, 
                                          :timeout    => 500000,
                                          :cast       => false,
                                          :pool       => 30
                                          )




      ## ActiveRecord::Base.connection.execute("BEGIN TRANSACTION; END;")

   end

end

## =====================================================================

class TriggerProduct < ActiveRecord::Base
   validates_presence_of   :filename
   # validates_uniqueness_of :filename
   validates_presence_of   :filetype  
   validates_presence_of   :detection_date
   validates_presence_of   :sensing_start
   validates_presence_of   :sensing_stop
   validates_presence_of   :runtime_status
   validates_presence_of   :initial_status
   
   # ----------------------------------------------
   
   # Currently we sort by start-time
   def <=>(other)
      return self.sensing_start <=> other.sensing_start
   end
   # ----------------------------------------------
   
end


## =====================================================================

class Pending2QueueFile < ActiveRecord::Base
   self.table_name   = 'pending2queue_files'
   self.primary_key  = 'trigger_product_id'   

   validates_presence_of   :filename
   validates_presence_of   :filetype
   
   belongs_to  :trigger_products,
               :class_name    => "TriggerProduct",
               :foreign_key   => "trigger_product_id"
   
   # ----------------------------------------------   
   
   def Pending2QueueFile.getPendingFiles
      arrFiles       = Array.new
      pendingFiles   = Pending2QueueFile.all 

      pendingFiles.each{|pendingFile| arrFiles << pendingFile }
      return arrFiles
   end   
   # ----------------------------------------------


end

## =====================================================================


## ========================================================================
##
## Class OrchestratorQueue tables

class OrchestratorQueue < ActiveRecord::Base
   self.table_name   = 'orchestrator_queue'
   self.primary_key  = 'trigger_product_id'

   belongs_to  :trigger_products,
               :class_name    => "TriggerProduct",
               :foreign_key   => "trigger_product_id"
   
   ## ----------------------------------------------   
   
   def OrchestratorQueue.getAllQueuedByName(filename)
      arrFiles     = Array.new
      triggerFiles = TriggerProduct.all
      queuedFiles  = OrchestratorQueue.all

      triggerFiles.each{|triggerFile|
         if triggerFile.filename != filename then
            next
         end
         queuedFiles.each{|queuedFile|
            if triggerFile.id == queuedFile.trigger_product_id then
               arrFiles << triggerFile
            end
         }         
      }
      return arrFiles   
   end
   ## ----------------------------------------------
   
   def OrchestratorQueue.getQueuedFiles
      arrFiles     = Array.new
      triggerFiles = TriggerProduct.all
      queuedFiles  = OrchestratorQueue.all
 
      triggerFiles.each{|triggerFile|
         queuedFiles.each{|queuedFile|
            if triggerFile.id == queuedFile.trigger_product_id then
               arrFiles << triggerFile
            end
         }         
      }
      return arrFiles
   end
   ## ----------------------------------------------   

   def OrchestratorQueue.getQueuedFile(jobId)
      queuedFile = OrchestratorQueue.find_by_trigger_product_id(jobId)
      if queuedFile == nil then
         return nil
      end
      aTrigger   = TriggerProduct.find_by_id(jobId)
      return aTrigger
   end
   ## ----------------------------------------------

end

#=====================================================================

class FailingTriggerProduct < ActiveRecord::Base
   self.primary_key  = 'trigger_product_id'
   

   belongs_to  :trigger_products,
               :class_name    => "TriggerProduct",
               :foreign_key   => "trigger_product_id"

end

#=====================================================================

class SuccessfulTriggerProduct < ActiveRecord::Base
   self.primary_key  = 'trigger_product_id'
   
   belongs_to  :trigger_products,
               :class_name    => "TriggerProduct",
               :foreign_key   => "trigger_product_id"
end

#=====================================================================

class DiscardedTriggerProduct < ActiveRecord::Base
   self.primary_key  = 'trigger_product_id'
   
   belongs_to  :trigger_products,
               :class_name    => "TriggerProduct",
               :foreign_key   => "trigger_product_id"
end

## =====================================================================

class ObsoleteTriggerProduct < ActiveRecord::Base
   self.primary_key  = 'trigger_product_id'   

   belongs_to  :trigger_products,
               :class_name    => "TriggerProduct",
               :foreign_key   => "trigger_product_id"
   
   # ----------------------------------------------   
   
   def ObsoleteTriggerProduct.getObsoleteFiles
      arrFiles       = Array.new
      triggerFiles   = TriggerProduct.all
      obsoleteFiles  = ObsoleteTriggerProduct.all

      triggerFiles.each{|triggerFile|
         obsoleteFiles.each{|queuedFile|
            if triggerFile.id == queuedFile.trigger_product_id then
               arrFiles << triggerFile
            end
         }         
      }
      return arrFiles
   end   
   # ----------------------------------------------   

end

#class Pending2QueueFile_OLD_TO_BE_REMOVED < ActiveRecord::Base
#   self.table_name   = 'pending2queue_files'
#
#   validates_presence_of   :filename
#   validates_presence_of   :filetype
#   validates_presence_of   :detection_date
#   #---------------------------------------------- 
#   
#   def Pending2QueueFile.getPendingFiles
#      arrFiles       = Array.new
#      pendingFiles   = Pending2QueueFile.all 
#
#      pendingFiles.each{|pendingFile| arrFiles << pendingFile }
#      return arrFiles
#   end   
#   #----------------------------------------------
#end

#=====================================================================

class ProductionTimeline < ActiveRecord::Base
   validates_presence_of   :file_type
   validates_presence_of   :sensing_start
   validates_presence_of   :sensing_stop

   # -----------------------------------------------------------------

   def ProductionTimeline.addSegment(type, start, stop)
      oneSecond = 1/(24.0*60.0*59.0)

      # Add one second to the boundaries to merge consecutive segments if any
      # -------       -------
      #        -------
      #
      # ---------------------
      #

      expandedStart = start - oneSecond
      expandedStop  = stop  + oneSecond

#       s_start = start.strftime("%Y%m%d%H%M%S")
#       s_stop  = stop.strftime("%Y%m%d%H%M%S")

      s_start = expandedStart.strftime("%Y%m%d%H%M%S")
      s_stop  = expandedStop.strftime("%Y%m%d%H%M%S")
      

      # Look for a timeline that completely covers the new segment
      arrTimeLines = ProductionTimeline.find(:all, :conditions=> "file_type = '#{type}' AND (sensing_start <= #{s_start} AND sensing_stop >= #{s_stop})")

      if (arrTimeLines.size > 0) then
         puts "INFO : This timeline is already present for #{type}... :-|"
         return
      end

      # Look for timeline bounds inside the new segment's time interval
      # If there are any, we merge them.

      arrTimeLines = ProductionTimeline.find(:all, :conditions=> "file_type = '#{type}' AND ((sensing_start >= #{s_start} AND sensing_start <= #{s_stop}) OR (sensing_stop >= #{s_start} AND sensing_stop <= #{s_stop}))")

      ProductionTimeline.transaction do

         if (arrTimeLines.size > 0) then
   
            arrTimeLines.each{|seg|
               
               # Merge Timeline segments
               seg.destroy
               
               tmp = seg.sensing_start
               seg_start = DateTime.new(tmp.strftime("%Y").to_i, tmp.strftime("%m").to_i, tmp.strftime("%d").to_i, tmp.strftime("%H").to_i, tmp.strftime("%M").to_i, tmp.strftime("%S").to_i)
               tmp = seg.sensing_stop
               seg_stop  = DateTime.new(tmp.strftime("%Y").to_i, tmp.strftime("%m").to_i, tmp.strftime("%d").to_i, tmp.strftime("%H").to_i, tmp.strftime("%M").to_i, tmp.strftime("%S").to_i)

               if (start > seg_start) then
                  start = seg_start
               end

               if (stop < seg_stop) then
                  stop = seg_stop
               end      
            }

         end

         newLine = ProductionTimeline.new(:file_type => type, :sensing_start => start, :sensing_stop => stop)

         newLine.save!

      end
   end
   # -----------------------------------------------------------------

   def ProductionTimeline.searchAllWithinInterval(filetype, start, stop, bIncStart=false, bIncEnd=false)
      arrFiles    = Array.new
      arrResult   = Array.new

      # if no filetype is specified, retrieve everything
      if filetype != nil and filetype != "" then
         arrFiles = ProductionTimeline.find_all_by_file_type(filetype)
      else
         return nil
      end

      # if start and stop criteria are defined, filter files
      if start != nil and stop != nil and start != "" and stop != "" then

         arrFiles.each{|aFile|
           
            # if the file is missing a valid validity interval, discard it
            if aFile.sensing_start == nil or aFile.sensing_stop == nil then
               next
            end

            # patch because accessors return a Time object instead of DateTime
            file_start = DateTime.parse(aFile.sensing_start.strftime("%Y%m%dT%H%M%S"))
            file_stop  = DateTime.parse(aFile.sensing_stop.strftime("%Y%m%dT%H%M%S"))

            # if the file's validity is entirely outside the bounds, discard it
            if (file_stop < start) or (file_start > stop) then
               next
            end

            # strict validity check on lower bound
            if (file_start < start) and (bIncStart == false) then
               next
            end

            # strict validity check on upper bound
            if (file_stop > stop) and (bIncEnd == false) then
               next
            end

            arrResult << aFile

         }

      else
         arrFiles.each{|aFile|
            
            arrResult.push(aFile)
         }
      end

      return arrResult

   end
   # -----------------------------------------------------------------

end
#=====================================================================

class RunningJob < ActiveRecord::Base
end

#=====================================================================

class OrchestratorMessage < ActiveRecord::Base
   self.table_name   = 'orchestrator_messages'
end

class MessageParameter < ActiveRecord::Base
   self.table_name   = 'message_parameters'

   belongs_to  :orchestrator_messages,
               :class_name    => "OrchestratorMessage",
               :foreign_key   => "orchestrator_message_id"

end

#=====================================================================
