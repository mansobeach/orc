#!/usr/bin/env ruby

# == Synopsis
#
# This is an NRTP Orchestrator command line tool used to retrieve the ID of a Job-order (trigger-product)
# giving the name of the conserned file. 
# 
# -f flag:
#
# Mandatory flag. This option is used to specify the name of the trigger_product_file for which the ID is needed.  
#
#
# == Usage
# retrieveJobOrderId.rb -f <file-name>  |  -j <joborder-id>
#     --file <file-name>         it specifies the name of the file
#     --job  <joborder-id>       it specifies the joborder-id
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
# CVS: $Id: retrieveJobOrderId.rb,v 1.3 2008/08/05 10:23:17 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require "orc/ORC_DataModel"
require "cuc/EE_ReadFileName"

# Global variables
@@dateLastModification = "$Date: 2008/08/05 10:23:17 $"   # to keep control of the last modification
                                       # of this script
                                       # execution showing Debug Info


# MAIN script function
def main

   # Data provided by the user
   @filename               = ""
   @jobid                  = ""
   @isDebugMode            = false
   
   opts = GetoptLong.new(
     ["--file", "-f",            GetoptLong::REQUIRED_ARGUMENT],
     ["--job", "-j",             GetoptLong::REQUIRED_ARGUMENT],
     ["--Debug", "-D",           GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",           GetoptLong::NO_ARGUMENT],
     ["--version", "-v",         GetoptLong::NO_ARGUMENT],
     ["--help", "-h",            GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"     then @isDebugMode = true
            when "--version" then	    
               print("\nESA - DEIMOS-Space S.L. ", File.basename($0), " $Revision: 1.3 $  [", @@dateLastModification, "]\n\n\n")
               exit(0)
	         when "--file"          then @filename           =  arg.to_s
            when "--job"           then @jobid              =  arg.to_s
			   when "--help"          then RDoc::usage
	         when "--usage"         then RDoc::usage("usage")
         end
      end
   rescue Exception
      exit(99)
   end

   ######################## Coherency Checks  ########################
   if @filename == "" and @jobid == "" then
      puts
      RDoc::usage("usage")
      puts
      exit(99)   
   end
   
   if @filename != "" and @jobid != "" then
      puts
      RDoc::usage("usage")
      puts
      exit(99)   
   end   
   


   #=================== Database Seach =================== 

   jobOrder = nil
   
   #---------------------------------------------------
   # Search by filename
   
   if @filename != "" then
      jobOrder = TriggerProduct.find_by_filename("#{File.basename(@filename)}")

      if jobOrder != nil then
         puts jobOrder.id
      else
         puts "-1"
      end
      exit(0)
   end
   #---------------------------------------------------

   if @jobid != "" then
      jobOrder = TriggerProduct.find_by_id("#{@jobid}")

      if jobOrder != nil then
         puts jobOrder.filename
      else
         puts "-1"
      end
      exit(0)
   end

end


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
