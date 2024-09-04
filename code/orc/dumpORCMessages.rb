#!/usr/bin/env ruby

# == Synopsis
#
# This is a SMOS NRTP Orchestrator command line tool that extracts a list of orchestrator messages from DB.
# Messages are searched by source or by target. The result is given as an xml output file. 
# 
# 
# -t flag:
#
# This flag is used to specify the target-type of the messages to dump.
#
#
# -s flag:
#
# This flag is used specify the source-type of the messages to dump.
#
#
# -i flag:
#
# This flag is used specify the id of the source/target of the messages to dump.
#
#
# -L flag:
#
# This flag is used to specify Location (full path + file-name) of the xml output file.
#
#
# == Usage
# dumpORCMessages.rb (-t <target-type> | -s <source-type>) -i <id> -L <full_name>
#
#     --source  <source-type>    it specifies the source-type of the messages to dump.
#     --target  <target-type>    it specifies the target-type of the messages to dump.
#     --id      <src/tgt id>     it specifies the source/target id of the messages to dump.
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
# CVS: $Id: dumpORCMessages.rb,v 1.2 2008/07/03 11:39:05 decdev Exp $
#
#########################################################################

require "rubygems"

require 'getoptlong'
require 'rdoc/usage'

require "orc/MessagesManager"

# Global variables
@@dateLastModification = "$Date: 2008/07/03 11:39:05 $"   # to keep control of the last modification
                                       # of this script
                                       # execution showing Debug Info


# MAIN script function
def main

   @full_report_name           = ""
   @source_type                = ""
   @target_type                = ""
   @src_tgt_id                 = ""

   @isDebugMode            = false
   
   opts = GetoptLong.new(
     ["--Location", "-L",     GetoptLong::REQUIRED_ARGUMENT],
     ["--source",   "-s",     GetoptLong::REQUIRED_ARGUMENT],
     ["--target",   "-t",     GetoptLong::REQUIRED_ARGUMENT],
     ["--id",       "-i",     GetoptLong::REQUIRED_ARGUMENT],
     ["--Debug",    "-D",     GetoptLong::NO_ARGUMENT],
     ["--usage",    "-u",     GetoptLong::NO_ARGUMENT],
     ["--version",  "-v",     GetoptLong::NO_ARGUMENT],
     ["--help",     "-h",     GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"     then @isDebugMode = true
            when "--version" then	    
               print("\nESA - DEIMOS-Space S.L. ", File.basename($0), " $Revision: 1.2 $  [", @@dateLastModification, "]\n\n\n")
               exit(0)
	         when "--Location"          then @full_report_name   = arg.to_s
	         when "--target"            then @target_type        = arg.to_s
            when "--source"            then @source_type        = arg.to_s
            when "--id"                then @src_tgt_id         = arg.to_s
			   when "--help"              then RDoc::usage
	         when "--usage"             then RDoc::usage("usage")
         end
      end
   rescue Exception
      exit(99)
   end


   #======== Check all flags and combinations ========#

   if @target_type == "" and @source_type == "" then
      puts
      puts "Please specify the source-type or the target-type of the messages !"
      puts
      exit(99)
   end

   if @target_type != "" and @source_type != "" then
      puts
      puts "Please specify either the source-type OR the target-type of the messages !"
      puts
      exit(99)
   end

   if @src_tgt_id == "" then
      puts
      puts "Please specify the source/target id of the messages !"
      puts
      exit(99)
   end

   if @full_report_name == "" or @full_report_name.slice(0,1) != "/" then
      puts
      puts "Please specify the output-file name (full-path + filename) ..."
      puts
      exit(99)
   end

   #============== Process user request ==============#
   
   mm = MessagesManager.new

   if @source_type != "" then
      mm.dumpMessagesBySrc(@full_report_name, @source_type, @src_tgt_id)
   else
      mm.dumpMessagesByTgt(@full_report_name, @target_type, @src_tgt_id)
   end

   #====================== end =======================#

end


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
