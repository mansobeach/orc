#!/usr/bin/env ruby

# == Synopsis
#
# This is a MINARC command line tool that registers production sensing time. 
# 
# 
# -f flag:
#
# Mandatory flag. This option is used to specify the file to be registered. 
#
#
# -t flag:
#
# Optional flag.
#
#
# -T flag:
#
# Optional flag.
#
#
# == Usage
# registerProduction.rb -f <file> | -l -t <file-type>
#     --file <file>              file whose production is registered
#     --list                     it lists production timeline
#     --type <file-type>         specifies production file-type to be queried
#     --Types                    it shows production file-types
#     --help                     shows this help
#     --usage                    shows the usage
#     --Debug                    shows Debug info during the execution
#     --version                  shows version number
#
# 
# == Author
# DEIMOS-Space S.L. (BOLF)
#
#
# == Copyright
# Copyright (c) 2009 ESA - DEIMOS Space S.L.
#

#########################################################################
#
# === Ruby source for #registerProduction.rb module
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === MDS-LEGOS -> ORC Component
# 
# CVS: $Id: registerProduction.rb,v 1.4 2009/03/13 09:08:41 decdev Exp $
#
# module ORC
#
#########################################################################


require 'getoptlong'
require 'rdoc/usage'

require "cuc/EE_ReadFileName"
require "orc/ORC_DataModel"
require "orc/ReadJobOrderFile"


# MAIN script function
def main

   @full_path_filename     = ""
   @filetype               = ""
   @triggerName            = ""
   @isDebugMode            = false
   @bList                  = false
   @bShowVersion           = false
   @bShowFileTypes         = false
   
   opts = GetoptLong.new(
     ["--file", "-f",            GetoptLong::REQUIRED_ARGUMENT],
     ["--type", "-t",            GetoptLong::REQUIRED_ARGUMENT],
     ["--Types", "-T",           GetoptLong::NO_ARGUMENT],
     ["--list", "-l",            GetoptLong::NO_ARGUMENT],
     ["--Debug", "-D",           GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",           GetoptLong::NO_ARGUMENT],
     ["--version", "-v",         GetoptLong::NO_ARGUMENT],
     ["--help", "-h",            GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"       then @isDebugMode  = true
            when "--list"        then @bList        = true
            when "--version"     then @bShowVersion = true
	         when "--file"        then @full_path_filename = arg.to_s
	         when "--type"        then @filetype           = arg.to_s.upcase
	         when "--trigger"     then @triggerName        = arg.to_s
            when "--Types"       then @bShowFileTypes      = true
			   when "--help"        then RDoc::usage
	         when "--usage"       then RDoc::usage("usage")
         end
      end
   rescue Exception
      exit(99)
   end
 
   if @bShowFileTypes == true then
      showFileTypes
      exit(0)
   end

   if @filetype == "" and @bList == true then
      RDoc::usage("usage")
   end

   if @full_path_filename == "" and @bList == false then
      RDoc::usage("usage")
   end

   if @bList == true then
      queryProduction(@filetype)
      exit(0)
   end

   fname = File.basename(@full_path_filename)

   #=== Prepare timeline command ===#

   type  = ""
   name  = File.basename(@full_path_filename)
   start = nil
   stop  = nil
   
   if @filetype == "" then

      nameDecoder = CUC::EE_ReadFileName.new(name)

      if nameDecoder.isEarthExplorerFile? == true then
         type   = nameDecoder.fileType
         start  = nameDecoder.start_as_dateTime
         stop   = nameDecoder.stop_as_dateTime      
      end

      if nameDecoder.isEarthExplorerFile? == false then
      
         ret = isType_MIRAS_L1C_BUFR?(name)
         
         # Load MIRAS_L1C_BUFR plug-in
         if ret == true then
            fileType = "MIRAS_L1C_BUFR"
            
            handler  = ""
            
            rubylibs = ENV['RUBYLIB'].split(':')
            
            rubylibs.each {|path|
               if File.exists?("#{path}/orc/plugins/#{fileType.upcase}_Handler.rb") then
                  handler = "#{fileType.upcase}_Handler"
                  break
               end
            }

            if handler == "" then
               puts "Fatal Error in registerProduction.rb !"
               puts
               puts "Could not find handler-file for file-type #{fileType.upcase} :-("
               puts
               exit(99)
            end
            
            require "orc/plugins/#{handler}"
            
            nameDecoderKlass  = eval(handler)
            nameDecoder       = nameDecoderKlass.new(name)
            
            if nameDecoder != nil and nameDecoder.isValid == true then
               type  = nameDecoder.fileType.upcase
               start = nameDecoder.start_as_dateTime
               stop  = nameDecoder.stop_as_dateTime
            else
               puts
               puts "#{name} could not be identified as a true #{fileType.upcase}"
               puts
               puts "Unable to manage #{name} ! :-("
               puts
               exit(99)
            end
         else
            puts
            puts "Unknown file family-type 4 #{name} !"
            puts
            exit(99)
         end    
      end


#       if nameDecoder.isEarthExplorerFile? == false then
#          puts
#          puts "Please specify file-type for non-EE Files !"
#          puts
#          exit(99)
#       end
# 
#       if nameDecoder.fileType == nil or nameDecoder.fileType == "" then
#          puts
#          puts "Could not identify EE file-type for #{name} :-("
#          puts "Unable tu update production-timelines !"
#          puts "Unable to store #{name} :-("
#          exit(99)
#       else
#          type   = nameDecoder.fileType
#          start  = nameDecoder.start_as_dateTime
#          stop   = nameDecoder.stop_as_dateTime
#       end
 
   end

   #------------------------------------
   
   # Super - Dirty - Patch (one more time !! D.P.)

   if type == "MPL_JOBORD" then
      jobReader   = ORC::ReadJobOrderFile.new(@full_path_filename)
      arrOutputs  = jobReader.getOutputsList
      arrOutputs.each{|outFile|
         ProductionTimeline.transaction do
            begin
               ProductionTimeline.addSegment(outFile[:fileType], start, stop)
            rescue Exception => e      
               puts
               puts "Failed to register production 4 #{outType[:fileType]} :-("
               puts
            end
         end
      }
      exit(0)
   end

   #------------------------------------

   ProductionTimeline.transaction do
      
      begin
         ProductionTimeline.addSegment(type[0..19], start, stop)
      rescue Exception => e      
         puts
         puts "Failed to register production 4 #{name} :-("
         puts
         exit(99)
      end
   end
   #------------------------------------


end

#-------------------------------------------------------------

def queryProduction(fileType)
   arrSegments = ProductionTimeline.find_all_by_file_type(fileType)
   
   if arrSegments.length > 0 then
      puts
      puts "===================== #{arrSegments[0].file_type} =============================="
      print "START----------------------------STOP--------------------------"
      puts
   end
   
   arrSegments.each{|segment|
      print segment.sensing_start, " - ", segment.sensing_stop
      puts
   }
end

#-------------------------------------------------------------

def showFileTypes

   arrTypes = ProductionTimeline.find_by_sql "select distinct(file_type) from production_timelines;"

   arrTypes.each{|timeline|
      puts timeline.file_type
   }

end

#-------------------------------------------------------------

def isType_MIRAS_L1C_BUFR?(filename)
   if filename.slice(0,5) != "miras" then
      return false
   end
   if File.extname(filename) != ".bufr" then
      return false
   end
   return true
end
#-------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
