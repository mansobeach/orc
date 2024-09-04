#!/usr/bin/env ruby

# == Synopsis
#
# This is a SMOS NRTP Orchestrator command line tool that shows the different portions of the production timeline
# for a given file-type.
# 
# 
# -t flag:
#
# This flag is used to specify the file-type to inspect.
#
#
# == Usage
# inspectProductionTimelines.rb -t file-type
#
#     --type <file-type>         it specifies the file-type of the timeline to inspect
#     --help                     shows this help
#     --usage                    shows the usage
#     --Debug                    shows Debug info during the execution
#     --version                  shows version number
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
# CVS: $Id: inspectProductionTimelines.rb,v 1.1 2008/07/02 16:41:00 decdev Exp $
#
#########################################################################

require "rubygems"
require "active_record"

require 'getoptlong'
require 'rdoc/usage'

require "orc/ORC_DataModel"
require "orc/GapsExtractor"

# Global variables
@@dateLastModification = "$Date: 2008/07/02 16:41:00 $"   # to keep control of the last modification
                                       # of this script
                                       # execution showing Debug Info


# MAIN script function
def main

   @filetype               = ""

   @isDebugMode            = false
   
   opts = GetoptLong.new(
     ["--type",     "-t",              GetoptLong::REQUIRED_ARGUMENT],
     ["--Debug", "-D",                 GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",                 GetoptLong::NO_ARGUMENT],
     ["--version", "-v",               GetoptLong::NO_ARGUMENT],
     ["--help", "-h",                  GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"     then @isDebugMode = true
            when "--version" then	    
               print("\nESA - DEIMOS-Space S.L. ", File.basename($0), " $Revision: 1.1 $  [", @@dateLastModification, "]\n\n\n")
               exit(0)
	         when "--type"              then @filetype            = arg.to_s.upcase
			   when "--help"              then RDoc::usage
	         when "--usage"             then RDoc::usage("usage")
         end
      end
   rescue Exception
      exit(99)
   end


   #======== Check all flags and combinations ========#

   if @filetype == nil or @filetype == "" then
      puts
      puts "Please specify the file-type of the production timeline to inspect ..."
      puts
      exit(99)
   end

   #============== Process user request ==============#
   
   # Extract all portions of the production timeline for the given file-type
   arrTimeLines = ProductionTimeline.find(:all, :conditions => "file_type = '#{@filetype}'")

   gp = GapsExtractor.new(arrTimeLines, @filetype, nil, nil)

   gp.extractIntervalsToConsole()

   #====================== end =======================#

end


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
