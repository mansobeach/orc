#!/usr/bin/env ruby

# == Synopsis
#
# This is a MINARC command line tool that archives a given file. 
# If such file or a file with exactly same filename is already 
# archived in the system, an error will be raised.
# 
# 
# -f flag:
#
# Mandatory flag. This option is used to specify the file to be archived. 
# File must be specified with the full path location.
#
#
# -t flag:
#
# Optional flag. This flag is used to specify the file-type of the file to be archived.
# By default MINARC will determine the file-type automatically, nevertheless 
# such classification may be overidden using this parameter. 
# In case MINARC fails to determine the file-type, it shall be specified by this flag. 
#
#
# -trigger flag:
# Optional flag. Specifies the name of the related trigger product file.
#
# -m flag:
#
# Optional flag. This flag is used to "move" specified source file to the Archive.
# Source file location must be in the same Archive filesystem ($MINARC_ARCHIVE_ROOT).
# By default minArcStore.rb copies source file from the specified location and optionally
# once it is archived it deletes it (see "-d" flag). This flag is not compatible with -d flag.
#
#
# == Usage
# minArcStore.rb -f <full_path_file> [-t type-of-the-file] [-m]
#     --file <full_path_file>    specifies the file to be archived
#     --type <file-type>         specifies the file-type of the file to be archived
#     --trigger <file-name>      specifies the name of the related trigger files
#     --move                     its moves the file to the Archive
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
# === Mini Archive Component (MinArc)
#
# CVS: $Id: minarcOrcStore.rb,v 1.5 2008/10/24 10:29:05 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require "cuc/EE_ReadFileName"
require "orc/ORC_DataModel"

# MAIN script function
def main

   @full_path_filename     = ""
   @filetype               = ""
   @triggerName            = ""
   @isDebugMode            = false
   @bMove                  = false
   @bShowVersion           = false
   
   opts = GetoptLong.new(
     ["--file", "-f",            GetoptLong::REQUIRED_ARGUMENT],
     ["--type", "-t",            GetoptLong::REQUIRED_ARGUMENT],
     ["--trigger",               GetoptLong::REQUIRED_ARGUMENT],
     ["--move", "-m",            GetoptLong::NO_ARGUMENT],
     ["--Debug", "-D",           GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",           GetoptLong::NO_ARGUMENT],
     ["--version", "-v",         GetoptLong::NO_ARGUMENT],
     ["--help", "-h",            GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"       then @isDebugMode  = true
            when "--move"        then @bMove        = true
            when "--version"     then @bShowVersion = true
	         when "--file"        then @full_path_filename = arg.to_s
	         when "--type"        then @filetype           = arg.to_s.upcase
	         when "--trigger"     then @triggerName        = arg.to_s
            when "--Types"       then bShowFileTypes      = true
			   when "--help"        then RDoc::usage
	         when "--usage"       then RDoc::usage("usage")
         end
      end
   rescue Exception
      exit(99)
   end
 
   if @bShowVersion then
      cmd = "\\minArcStore.rb --version"
      system(cmd)
      exit(0)
   end


   #<PATCH> miras bufr files auto-detection
   fname = File.basename(@full_path_filename)
   if fname[0..4] == "miras" and fname.include?("_l1c.bufr") then
      @filetype = "MIRAS_L1C_BUFR"
   end
   #</PATCH>

   #=== Prepare achive command ===#
   cmd = "\\minArcStore.rb -f #{@full_path_filename}"

   if @filetype != "" then
      cmd << " -t #{@filetype}" 
   end

   if @bMove then
      cmd << " -m"
   end

   if @triggerName != "" then
      cmd << " -a trigger_product_name:#{@triggerName}"
   end

   if @isDebugMode then
      cmd << " -D"
   end

   #=== Prepare timeline command ===#
   type  = ""
   name  = File.basename(@full_path_filename)
   start = nil
   stop  = nil
   
   if @filetype == "" then

      nameDecoder = CUC::EE_ReadFileName.new(name)

      if nameDecoder.isEarthExplorerFile? == false then
         puts
         puts "Please specify file-type for non-EE Files !"
         puts
         exit(99)
      end

      if nameDecoder.fileType == nil or nameDecoder.fileType == "" then
         puts
         puts "Could not identify EE file-type for #{name} :-("
         puts "Unable tu update production-timelines !"
         puts "Unable to store #{name} :-("
         exit(99)
      else
         type   = nameDecoder.fileType
         start  = nameDecoder.start_as_dateTime
         stop   = nameDecoder.stop_as_dateTime
      end
   else
      handler = ""
      rubylibs = ENV['RUBYLIB'].split(':')
      rubylibs.each {|path|
         if File.exists?("#{path}/minarc/plugins/#{@filetype}_Handler.rb") then
            handler = "#{@filetype}_Handler"
            break
         end
      }

      if handler == "" then
         puts
         puts "Could not find handler-file for file-type #{@filetype}..."
         puts "Unable tu update production-timelines !"
         puts "Unable to store #{name} :-("
         exit(99)
      else
         require "minarc/plugins/#{handler}"
         nameDecoderKlass = eval(handler)
         nameDecoder = nameDecoderKlass.new(name)
            
         if nameDecoder != nil and nameDecoder.isValid == true then
            type  = nameDecoder.fileType.upcase
            start = nameDecoder.start_as_dateTime
            stop  = nameDecoder.stop_as_dateTime
         else
            puts
            puts "The file #{name} could not be identified as a valid #{@filetype} file..."
            puts "Unable to store #{name} :-("
            exit(99)
         end     
      end
   end


   #=== Execute as a transaction ===#

   ProductionTimeline.transaction do
      
      ProductionTimeline.addSegment(type[0..19], start, stop)
      
      archResult = system(cmd)

      if !archResult then
         puts
         puts "Failed to store #{name} :-("
         exit(99)
      end

   end
   
end

#-------------------------------------------------------------


#-------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
