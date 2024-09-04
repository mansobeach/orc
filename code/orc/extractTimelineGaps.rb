#!/usr/bin/env ruby

# == Synopsis
#
# This is a SMOS NRTP Orchestrator command line tool that extracts gaps from the production timeline
# for a given file-type and in a given time interval. The result is given as an xml output file. 
# 
# 
# -t flag:
#
# This flag is used to specify the file-type for which the user wants to
# extract the production timeline gaps.
#
#
# -s flag:
#
# This flag is used specify the start of the time interval in which the user is looking for gaps.
# This flag must be specified together "-e" flag. See below "-e" flag specification.
#
#
# -e flag:
#
# This flag is used specify the end of the time interval in which the user is looking for gaps.
# This flag must be specified together "-s" flag. See above "-s" flag specification.
#
#
# -L flag:
#
# This flag is used to specify Location (full path + file-name) of the xml output file.
#
#
# == Usage
# extractTimelineGaps.rb -t file-type -s <start> -e <end> -L <full_name>
#
#     --type <file-type>         it specifies the file-type of the timeline to inspect
#     --start <YYYYMMDDThhmmss>  it specifies the lower bound of the time interval to inspect
#     --end   <YYYYMMDDThhmmss>  it specifies the higher bound of the time interval to inspect
#     --Location <full-path>     it specifies the full name of the desired output file
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
# CVS: $Id: extractTimelineGaps.rb,v 1.1 2008/05/28 16:46:00 decdev Exp $
#
#########################################################################

require "rubygems"
require "active_record"

require 'getoptlong'
require 'rdoc/usage'

require "orc/ORC_DataModel"
require "orc/GapsExtractor"

# Global variables
@@dateLastModification = "$Date: 2008/05/28 16:46:00 $"   # to keep control of the last modification
                                       # of this script
                                       # execution showing Debug Info


# MAIN script function
def main

   @full_report_name          = ""
   @filetype                  = ""
   @startVal                   = ""
   @endVal                     = ""

   @isDebugMode            = false
   
   opts = GetoptLong.new(
     ["--Location", "-L",              GetoptLong::REQUIRED_ARGUMENT],
     ["--type", "-t",                  GetoptLong::REQUIRED_ARGUMENT],
     ["--start", "-s",                 GetoptLong::REQUIRED_ARGUMENT],
     ["--end",   "-e",                 GetoptLong::REQUIRED_ARGUMENT],
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
	         when "--Location"          then @full_report_name   = arg.to_s
	         when "--type"              then @filetype           = arg.to_s.upcase
            when "--start"             then @startVal            = arg.to_s
            when "--end"               then @endVal              = arg.to_s
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


   begin
      @startVal = DateTime.parse(@startVal)
      @endVal   = DateTime.parse(@endVal)
   rescue Exception
      puts
      puts "Invalid date format or date out of bounds..."
      puts
      RDoc::usage("usage")
      exit(99)
   end

   if @startVal >= @endVal then
      puts
      puts "End date must be strictly greater than start date..."
      puts
      RDoc::usage("usage")
      exit(99)
   end

   if @full_report_name == "" or @full_report_name.slice(0,1) != "/" then
      puts
      puts "Please specify the output-file name (full-path + filename) ..."
      puts
      exit(99)
   end

   #============== Process user request ==============#
   
   # Extract all portions of the production timeline for the given file-type and time interval
   arrTimeLines = ProductionTimeline.searchAllWithinInterval(@filetype, @startVal, @endVal, true, true)

   # Extract the gaps and generate the output file
   extractor = GapsExtractor.new(arrTimeLines, @filetype, @startVal, @endVal)
   extractor.generateReport(@full_report_name)

   #====================== end =======================#

end


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
