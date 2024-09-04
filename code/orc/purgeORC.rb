#!/usr/bin/env ruby

# == Synopsis
#
# This is an Orchestrator command line tool that ***DELETES ALL QUEUES*** !
#
# ***BE CAREFUL*** using this tool because there is NO ROLLBACK  :-|
#
# 
# 
# -Y flag:
#
# This is a confirmation flag
#
# == Usage
# purgeORC.rb [-Y]
#     --YES        Confirmation required to delete all orchestrator tables
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
# === MDS-LEGOS (ORC)
#
# CVS: $Id: purgeORC.rb,v 1.2 2008/12/17 18:09:17 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require "orc/ORC_DataModel"


# MAIN script function

def main

   @bConfirmed  = false

   opts = GetoptLong.new(
     ["--Debug", "-D",           GetoptLong::NO_ARGUMENT],
     ["--YES",   "-Y",           GetoptLong::NO_ARGUMENT],
     ["--version", "-v",         GetoptLong::NO_ARGUMENT],
     ["--help", "-h",            GetoptLong::NO_ARGUMENT]
     )

   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"             then @isDebugMode = true
            when "--YES"               then @bConfirmed  = true
            when "--version"           then showVersion  = true
			   when "--help"              then RDoc::usage
	         when "--usage"             then RDoc::usage("usage")
         end
      end
   rescue Exception
      exit(99)
   end

   if @bConfirmed == false then
      RDoc::usage("usage")
   end


   #------------------------------------------------------------------
   puts
   puts "Clean up of Orchestrator tables"
   puts

   OrchestratorQueue.delete_all
   FailingTriggerProduct.delete_all
   SuccessfulTriggerProduct.delete_all
   ObsoleteTriggerProduct.delete_all
   TriggerProduct.delete_all
   ProductionTimeline.delete_all

   if Pending2QueueFile.table_exists?() == true then
      Pending2QueueFile.delete_all
   end
   
   exit(0)

end 
#-------------------------------------------------------------


#==========================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
