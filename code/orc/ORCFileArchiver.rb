#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #ORCFileArchiver class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Mini Archive Component (MinArc)
# 
# CVS: $Id: ORCFileArchiver.rb,v 1.1 2008/05/27 09:11:40 decdev Exp $
#
# module MINARC
#
#########################################################################

require "cuc/DirUtils"
require "cuc/EE_ReadFileName"
require "cuc/FT_PackageUtils"
require "minarc/MINARC_DatabaseModel"
require "orc/ORC_DataModel"

class ORCFileArchiver

   include CUC::DirUtils
   #-------------------------------------------------------------   
   
   # Class contructor
   # move : boolean. If true a move is made, otherwise it is moved from source
   # debug: boolean. If true it shows debug info.
   def initialize(bMove = false)
      @bMove               = bMove
      checkModuleIntegrity
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "FileArchiver debug mode is on"
   end
   #-------------------------------------------------------------

   # Main method of the class.
   def archive(full_path_file, fileType = "", triggerName = "", bDelete = false, bUnPack = false)

      # CHECK WHETHER SPECIFIED FILE EXISTS
      if File.exists?(full_path_file) == false then
         puts
         puts "#{full_path_file} does not exist ! :-("
         return false
      end

      fileName = ""

      if bUnPack == false then
         fileName = File.basename(full_path_file)
      else
         fileName = File.basename(full_path_file, ".*")
      end

      # CHECK WHETHER FILE IS NOT ALREADY ARCHIVED

      aFile = ArchivedFile.find_by_filename(fileName)

      if aFile != nil then
         puts
         puts "#{fileName} is already archived !"
         return false
      end

      if fileType == "" then
         nameDecoder = CUC::EE_ReadFileName.new(fileName)

         if nameDecoder.fileType == nil or nameDecoder.fileType == "" then
            puts
            puts "Could not identify EE file-type for #{fileName} :-("
            return false
         else
            fileType = nameDecoder.fileType
            start    = nameDecoder.start_as_dateTime
            stop     = nameDecoder.stop_as_dateTime
         end
      else
         handler = ""
         rubylibs = ENV['RUBYLIB'].split(':')
         rubylibs.each {|path|
            if File.exists?("#{path}/minarc/plugins/#{fileType.upcase}_Handler.rb") then
               handler = "#{fileType.upcase}_Handler"
               break
            end
         }

         if handler == "" then
            puts
            puts "Could not find handler-file for file-type #{fileType.upcase}..."
            puts "Storing #{fileName} without further processing :-|"
            puts

            fileType = fileType.upcase
            start = ""
            stop  = ""
         else
            require "minarc/plugins/#{handler}"
            nameDecoderKlass = eval(handler)
            nameDecoder = nameDecoderKlass.new(fileName)
            
            if nameDecoder != nil and nameDecoder.isValid == true then
               fileType = nameDecoder.fileType.upcase
               start = nameDecoder.start_as_dateTime
               stop  = nameDecoder.stop_as_dateTime
            else
               puts
               puts "The file #{fileName} could not be identified as a valid #{fileType.upcase} file..."
               puts "Unable to store #{fileName} :-("
               return false
            end     
         end
      end

      # Archiving transaction

      bstored = false

      #archive the file
      bstored = store(full_path_file, fileType[0..19], start, stop, triggerName, bDelete, bUnPack)

      if bstored then
         begin
            #update the timeline
            ProductionTimeline.addSegment(fileType[0..19], start, stop)         
         rescue Exception => e
            #unstore !
            puts
            puts e
            arrTmp = full_path_file.split("/")
            tmp_name = arrTmp[(arrTmp.length - 1)]
            puts tmp_name
            cmd = "\\minArcDelete.rb -f #{tmp_name}"
            system(cmd)
            puts "File has NOT been stored !"
         end
      else
         exit(99)
      end
   end
   #-------------------------------------------------------------

private

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true
      
      if !ENV['MINARC_ARCHIVE_ROOT'] then
         puts
         puts "MINARC_ARCHIVE_ROOT environment variable is not defined !\n"
         bDefined = false
      end

      if bCheckOK == false or bDefined == false then
         puts("FileArchiver::checkModuleIntegrity FAILED !\n\n")
         exit(99)
      end

      @archiveRoot = ENV['MINARC_ARCHIVE_ROOT']
      return
   end
   #-------------------------------------------------------------

   # It performs the storage in the archive
   def store(full_path_filename, type, start, stop, triggerName, bDelete, bUnPack)
      
      name = File.basename(full_path_filename, ".*")
      
      if @isDebugMode == true then
         puts "==================================="
         puts "--Inventory Info--"
         puts full_path_filename
         puts type
         puts start
         puts stop
         puts triggerName
         puts "==================================="
      end

      #-------------------------------------------
      # Copy the File

      if bUnPack == true then         
         checkDirectory("#{@archiveRoot}/#{type}/#{name}")
         cmd = "\\cp -f #{full_path_filename} #{@archiveRoot}/#{type}/#{name}"
      else
         checkDirectory("#{@archiveRoot}/#{type}")
         if @bMove == false then
            cmd = "\\cp -Rf #{full_path_filename} #{@archiveRoot}/#{type}"
         else
            cmd = "\\rm -rf #{@archiveRoot}/#{type}/#{File.basename(full_path_filename)}"
            system(cmd)
            cmd = "\\mv -f #{full_path_filename} #{@archiveRoot}/#{type}"
         end
      end
            
      if @isDebugMode == true then
         puts cmd
      end
      ret = system(cmd)

      if ret == false then
         puts "Could not copy #{full_path_filename} to the Archive ! :-("
         return false
      end

      
      #-------------------------------------------
      # Unpack the file

      if bUnPack == true then
         unpacker = FT_PackageUtils.new(File.basename(full_path_filename), "#{@archiveRoot}/#{type}/#{name}", true)
         if @isDebugMode == true then
            unpacker.setDebugMode
         end
         unpacker.unpack
      end

      #-------------------------------------------
      # Inventory the file

      anArchivedFile = ArchivedFile.new
      if bUnPack == true then
         anArchivedFile.filename       = File.basename(full_path_filename, ".*")
      else
         anArchivedFile.filename       = File.basename(full_path_filename)
      end
      anArchivedFile.filetype       = type
      anArchivedFile.archive_date   = Time.now
      if start != "" and start != nil then
         anArchivedFile.validity_start = start
      end

      if stop != "" and stop != nil then
         anArchivedFile.validity_stop = stop
      end

      anArchivedFile.trigger_product_name = triggerName

      begin
         anArchivedFile.save!
      rescue Exception => e
         puts
         puts e.to_s
         puts
         puts "Could not inventory #{anArchivedFile.filename}"
         return false
      end
      
      #-------------------------------------------
      # Delete Source file if requested
      if bDelete == true then
         cmd = "\\rm -Rf #{full_path_filename}"
         if @isDebugMode == true then
            puts cmd
         end
         ret = system(cmd)
      end

      return true

   end
   #-------------------------------------------------------------

end # class

#=====================================================================


#-----------------------------------------------------------


