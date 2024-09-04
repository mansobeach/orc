#!/usr/bin/env ruby

# == Synopsis
#
# This is a SMOS NRTP Orchestrator command line tool that stores a running job's Id in database. 
# 
# 
# -P flag:
#
# This flag is used to specify the Id of the processor.
#
# -J flag:
#
# This flag is used to specify the joborder Id of the running job.
#
#
# == Usage
# storeRunningJob.rb -P <processor-id> -J <joborder-id> 
#
#     --Processor-id <processor-id>    it specifies the Id of the processor.
#     --Joborder-id  <joborder-id>     it specifies the joborder Id of the running job.
#     --help                           shows this help
#     --usage                          shows the usage
#     --Debug                          shows Debug info during the execution
#     --version                        shows version number
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
# CVS: $Id: storeRunningJob.rb,v 1.2 2008/07/29 10:48:08 decdev Exp $
#
#########################################################################

require "rubygems"

require 'getoptlong'
require 'rdoc/usage'

require "orc/ORC_DataModel"

# Global variables
@@dateLastModification = "$Date: 2008/07/29 10:48:08 $"   # to keep control of the last modification
                                       # of this script
                                       # execution showing Debug Info


# MAIN script function
def main

   @processor_id           = 0
   @joborder_id            = 0

   @isDebugMode            = false
   
   opts = GetoptLong.new(
     ["--Processor-id",  "-P",     GetoptLong::REQUIRED_ARGUMENT],
     ["--Joborder-id",   "-J",     GetoptLong::REQUIRED_ARGUMENT],
     ["--Debug",         "-D",     GetoptLong::NO_ARGUMENT],
     ["--usage",         "-u",     GetoptLong::NO_ARGUMENT],
     ["--version",       "-v",     GetoptLong::NO_ARGUMENT],
     ["--help",          "-h",     GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"     then @isDebugMode = true
            when "--version" then	    
               print("\nESA - DEIMOS-Space S.L. ", File.basename($0), " $Revision: 1.2 $  [", @@dateLastModification, "]\n\n\n")
               exit(0)
	         when "--Processor-id"   then @processor_id  = arg.to_i
	         when "--Joborder-id"    then @joborder_id   = arg.to_i
			   when "--help"           then RDoc::usage
	         when "--usage"          then RDoc::usage("usage")
         end
      end
   rescue Exception => e
      puts e.to_s
      exit(99)
   end

   #======== Check all flags and combinations ========#

   if @processor_id == nil or @processor_id == 0 then
      puts
      puts "Missing Processor Id !"
      RDoc::usage
   end

   if @joborder_id == nil or @joborder_id == 0 then
      puts
      puts "Missing Joborder Id !"
      RDoc::usage
   end

   if @isDebugMode then
      puts
      puts "--- Storing new running job ---"
      puts "> Proc-id      : #{@processor_id}"
      puts "> Joborder-id  : #{@joborder_id}"
      puts "-------------------------------" 
      puts     
   end

   #============== Process user request ==============#

   aJob = RunningJob.new
   aJob.proc_id=@processor_id
   aJob.joborder_id = @joborder_id
      
   begin
      aJob.save!
   rescue Exception => e
      puts
      puts e.to_s
      puts
      exit(99)
   end
   
   #====================== end =======================#

   exit(0)

end

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
