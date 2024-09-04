#!/usr/bin/env ruby

# == Synopsis
#
# This is an NRTP Orchestrator command line tool used to look-up a trigger file in the orchestrators database.
# 
# -f flag:
#
# Mandatory flag. This option is used to specify the name of the file to be looked-up.  
#
# 
# -Q flag:
#
# Optional flag. This option specifies to look-up in the orchestrator queue table.
#
#
# -S flag:
#
# Optional flag. This option specifies to look-up in the orchestrator successful products table. 
#
# -F flag:
#
# Optional flag. This option specifies to look-up in the orchestrator failed products table.
#
#
# == Usage
# isOrcProductQueued.rb -f <file-name> -Q | -S | -F
#
#     --file <file-name>         specifies the name of the file to be looked-up
#     --Queue                    looks-up in the Queue
#     --Success                  looks-up in the Successfull products
#     --Failed                   looks-up in the Failed products
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
# CVS: $Id: isOrcProductQueued.rb,v 1.2 2008/12/16 09:59:19 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require "orc/ORC_DataModel"

# Global variables
@@dateLastModification = "$Date: 2008/12/16 09:59:19 $"   # to keep control of the last modification
                                       # of this script
                                       # execution showing Debug Info


# MAIN script function
def main


   # Data provided by the user
   @filename               = ""
   @queueName              = ""

   # Variables
   @triggerProd            = nil
   @product                = nil
   
   opts = GetoptLong.new(
     ["--file",       "-f",       GetoptLong::REQUIRED_ARGUMENT],
     ["--Debug",      "-D",       GetoptLong::NO_ARGUMENT],
     ["--usage",      "-u",       GetoptLong::NO_ARGUMENT],
     ["--version",    "-v",       GetoptLong::NO_ARGUMENT],
     ["--Failed",     "-F",       GetoptLong::NO_ARGUMENT],
     ["--Success",    "-S",       GetoptLong::NO_ARGUMENT],
     ["--Queue",      "-Q",       GetoptLong::NO_ARGUMENT],
     ["--help",       "-h",       GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"     then @isDebugMode = true
            when "--version" then	    
               print("\nESA - DEIMOS-Space S.L. ", File.basename($0), " $Revision: 1.2 $  [", @@dateLastModification, "]\n\n\n")
               exit(0)
            when "--Failed"        then @queueName           = "FAI"
            when "--Success"       then @queueName           = "SUC"
            when "--Queue"         then @queueName           = "QUE"
            when "--file"          then @filename            =  arg.to_s
			   when "--help"          then RDoc::usage
	         when "--usage"         then RDoc::usage("usage")
         end
      end
   rescue Exception => e
      puts e.message
      exit(99)
   end

   ################# Coherency Checks & Data Extraction ################ 


   if @filename == "" then
      RDoc::usage("usage")
      puts
      exit(99)
   end

   if @queueName == "" then
      puts
      puts "No queue specified for the search"
      puts
      RDoc::usage("usage")
      puts
      exit(99)
   end

   ######################## Request Processing ########################

   #look-up for the entry in the trigger products table
   @triggerProd = TriggerProduct.find_by_filename(@filename)
   if @triggerProd == nil then
      if @isDebugMode then
         puts "The file is not registered as a trigger product."
      end
      exit(-1)
   end
   

   if @queueName == "QUE" then
      #check if the file is registered in the orchestrator queue
      @product = OrchestratorQueue.find_by_trigger_product_id(@triggerProd.id)
      if @product == nil then
         if @isDebugMode then
            puts "File is not present in the queue"
         end
         exit(-1)
      else
         if @isDebugMode then
            puts "File is present in the processing queue  ;-)"
         end
         exit(0)
      end
   end

   if @queueName == "SUC" then
      #check if the file is registered in the successful products queue
      @product = SuccessfulTriggerProduct.find_by_trigger_product_id(@triggerProd.id)
      if @product == nil then
         if @isDebugMode then
            puts "File is not present in the successful products"
         end
         exit(-1)
      else
         if @isDebugMode then
            puts "File has been processed successfuly  :-)"
         end
         exit(0)
      end
   end

   if @queueName == "FAI" then
      #check if the file is registered in the failed products queue
      @product = FailingTriggerProduct.find_by_trigger_product_id(@triggerProd.id)
      if @product == nil then
         if @isDebugMode then
            puts "File is not present in the failing products"
         end
         exit(-1)
      else
         if @isDebugMode then
            puts "File has been found in the failed products list  :-("
         end
         exit(0)
      end
   end

   exit(99)

end


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
