#!/usr/bin/env ruby

# == Synopsis
#
# This is a SMOS NRTP Orchestrator command line tool that stores an ORC message in the database.
# The tool prints (stdout) the database ID received by the new message. 
# 
# 
# -S flag:
#
# This flag is used to specify the source-type of the message to store.
#
#
# -s flag:
#
# This flag is used specify source-id of the message to store.
#
#
# -T flag:
#
# This flag is used to specify the target-type of the message to store.
#
#
# -t flag:
#
# This flag is used specify target-id of the message to store.
#
#
# -M flag:
#
# This flag is used specify the message-type of the message to store.
#
#
# -P flag:
#
# Optional flag
# This flag is used to specify a list of parameters for the message to store.
# The argument string must follow the pattern : name1:value1:name2:value2...
#
#
# == Usage
# storeORCMessage.rb -S <source-type> -s <source-id> -T <target-type> -t <target-id> -M <message-type> [-P name1:value1:name2:value2] 
#
#     --Source-type     <source-type>    it specifies the source-type of the message to store.
#     --source-id       <source-id>      it specifies the source-id of the message to store.
#     --Target-type     <target-type>    it specifies the target-type of the message to store.
#     --target-id       <target-id>      it specifies the target-id of the message to store.
#     --Message-type    <message-type>   it specifies the message-type of the message to store.
#     --Params          <params_string>  it specifies a list of parameters for the message to store (optional).
#     --help                             shows this help
#     --usage                            shows the usage
#     --Debug                            shows Debug info during the execution
#     --version                          shows version number
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
# CVS: $Id: storeORCMessage.rb,v 1.1 2008/06/27 16:33:23 decdev Exp $
#
#########################################################################

require "rubygems"

require 'getoptlong'
require 'rdoc/usage'

require "orc/MessagesManager"

# Global variables
@@dateLastModification = "$Date: 2008/06/27 16:33:23 $"   # to keep control of the last modification
                                       # of this script
                                       # execution showing Debug Info


# MAIN script function
def main

   @source_type                = ""
   @source_id                  = ""
   @target_type                = ""
   @target_id                  = ""
   @message_type               = ""
   @arrParams                  = Array.new

   @isDebugMode            = false
   
   opts = GetoptLong.new(
     ["--Source-type",  "-S",     GetoptLong::REQUIRED_ARGUMENT],
     ["--source-id",    "-s",     GetoptLong::REQUIRED_ARGUMENT],
     ["--Target-type",  "-T",     GetoptLong::REQUIRED_ARGUMENT],
     ["--target-id",    "-t",     GetoptLong::REQUIRED_ARGUMENT],
     ["--Message-type", "-M",     GetoptLong::REQUIRED_ARGUMENT],
     ["--Params",       "-P",     GetoptLong::REQUIRED_ARGUMENT],
     ["--Debug",        "-D",     GetoptLong::NO_ARGUMENT],
     ["--usage",        "-u",     GetoptLong::NO_ARGUMENT],
     ["--version",      "-v",     GetoptLong::NO_ARGUMENT],
     ["--help",         "-h",     GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"     then @isDebugMode = true
            when "--version" then	    
               print("\nESA - DEIMOS-Space S.L. ", File.basename($0), " $Revision: 1.1 $  [", @@dateLastModification, "]\n\n\n")
               exit(0)
	         when "--Source-type"       then @source_type   = arg.to_s
	         when "--source-id"         then @source_id     = arg.to_s
            when "--Target-type"       then @target_type   = arg.to_s
            when "--target-id"         then @target_id     = arg.to_s
            when "--Message-type"      then @message_type  = arg.to_s
            when "--Params"            then parseParamString(arg.to_s)
			   when "--help"              then RDoc::usage
	         when "--usage"             then RDoc::usage("usage")
         end
      end
   rescue Exception => e
      puts e.to_s
      exit(99)
   end

   #======== Check all flags and combinations ========#

   if @source_type == "" or @source_id == "" then
      puts
      puts "Missing source definition : please specify source type and id for the message !"
      puts
      exit(99)
   end

   if @target_type == "" or @target_id == "" then
      puts
      puts "Missing target definition : please specify target type and id for the message !"
      puts
      exit(99)
   end

   if @message_type == "" then
      puts
      puts "Missing message-type : please specify a message-type for the message !"
      puts
      exit(99)
   end

   if @arrParams == nil then
      puts
      puts "Failed to parse parameter string, illegal number of values or wrong separator !"
      puts
      exit(99)
   end

   if @isDebugMode then
      puts
      puts "--- Storing new message ---"
      puts "> Source-type  : #{@source_type}"
      puts "> source-id    : #{@source_id}"
      puts "> Target-type  : #{@target_type}"
      puts "> target-id    : #{@target_id}"
      puts "> Message-type : #{@message_type}"
      
      if @arrParams.size > 0 then
         puts ">"
      end

      @arrParams.each{|p|
         puts "> #{p.to_s}"
      }
      puts "---------------------------" 
      puts     
   end

   #============== Process user request ==============#
   
   OrchestratorMessage.transaction do

      # Create the message
      aMessage = OrchestratorMessage.new
      aMessage.source_type  = @source_type
      aMessage.source_id    = @source_id
      aMessage.target_type  = @target_type
      aMessage.target_id    = @target_id
      aMessage.message_type = @message_type

      # Save the message
      begin
         aMessage.save!
      rescue Exception => e
         puts
         puts e.to_s
         puts
         exit(99)
      end

      # get the database ID of the message
      dbid = aMessage.id
   
      #Create and save the parameters
      @arrParams.each{|param|
         #create
         aParam = MessageParameter.new
         aParam.param_name  = param.param_name
         aParam.param_value = param.param_value
         aParam.orchestrator_message_id = dbid

         #save
         begin
            aParam.save!
         rescue Exception => e
            puts
            puts e.to_s
            puts
            exit(99)
         end
      }

      #output the database id of the new message
      puts dbid      

   end

   #====================== end =======================#

   exit(0)

end

def parseParamString(aString)
   arrTmp = aString.split(':')

   if arrTmp.size.modulo(2) != 0 then
      @arrParams = nil
      return
   end

   i=0
   while i <= (arrTmp.size - 2)
      @arrParams.push(ORCParameter.new(arrTmp[i], arrTmp[i+1]))
      i=i+2 
   end
end

class ORCParameter
      
   @param_name  = ""
   @param_value = ""

   def initialize (name, value)
      @param_name  = name
      @param_value = value
   end

   def to_s
      return "Parameter -> name = '#{@param_name}' and value = '#{@param_value}'"
   end

   def param_name
      return @param_name
   end

   def param_value
       return @param_value
   end
end

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
