#!/usr/bin/env ruby

# == Synopsis
#
# This is a SMOS NRTP Orchestrator command line tool that deletes a message from database on demand of the user.
# 
# -i flag:
#
# This flag is used specify the id of the message to delete.
#
#
#
# == Usage
# deleteORCMessage.rb -i <id>
#
#     --id      <src/tgt id>     it specifies the source/target of the messages to dump.
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
# CVS: $Id: deleteORCMessage.rb,v 1.1 2008/06/27 14:32:41 decdev Exp $
#
#########################################################################

require "rubygems"

require 'getoptlong'
require 'rdoc/usage'

require "orc/MessagesManager"

# Global variables
@@dateLastModification = "$Date: 2008/06/27 14:32:41 $"   # to keep control of the last modification
                                       # of this script
                                       # execution showing Debug Info


# MAIN script function
def main

   @message_id       = ""

   @isDebugMode      = false
   
   opts = GetoptLong.new(
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
               print("\nESA - DEIMOS-Space S.L. ", File.basename($0), " $Revision: 1.1 $  [", @@dateLastModification, "]\n\n\n")
               exit(0)
            when "--id"                then @message_id         = arg.to_s
			   when "--help"              then RDoc::usage
	         when "--usage"             then RDoc::usage("usage")
         end
      end
   rescue Exception
      exit(99)
   end


   #======== Check all flags and combinations ========#

   if @message_id == "" then
      puts
      puts "Please specify the id of the message to delete !"
      puts
      exit(99)
   end

   #============== Process user request ==============#
   
   mm = MessagesManager.new

   mm.deleteMessage(@message_id)

   #====================== end =======================#

end


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
