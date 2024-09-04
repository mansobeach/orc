#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #EE_ReadFileName class         
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Utils Component
# 
# CVS: $Id: EE_ReadFileName.rb,v 1.15 2009/04/21 12:02:18 decdev Exp $
#
# This class is used for reading the system filename.
# It decodes the UNIX/Linux Filename following the
# Earth Explorer filename conventions
#
#########################################################################

 
module CUC

class EE_ReadFileName

   attr_reader :fileType, :fileClass, :fileVersion, :startValidity, :stopValidity,
               :fileContent, :dateStart, :dateStop, :start_as_dateTime, :stop_as_dateTime,
               :fileNameType

   #-------------------------------------------------------------
   
   # Class constructor
   # - file (IN): File to be read
   def initialize(file, debugMode = false)
      @isDebugMode  = debugMode
      checkModuleIntegrity
      @filename     = file
      decodeFileName(file)
#       if isEarthExplorerFile(file) == true then
#          decodeFileName(file)
#       else
#          resetMembers
#          if @isDebugMode == true then
#             puts "#{@filename} is not an Earth Explorer file"
#          end
#       end
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode  = true
      puts "DCC_EE_ReadFileName debug mode is on"
   end
   #-------------------------------------------------------------

   def isEarthExplorerFile?
      return isEarthExplorerFile(@filename)
   end
   #-------------------------------------------------------------
   
   # This Method returns true if the given filename is an Earth Explorer
   # filename, otherwise it returns false
   def isEarthExplorerFile(filename)

      if filename.slice(2, 1) != "_" then
         # puts "MAAAAL 2,1"
         return false
      end

      if filename.slice(7, 1) != "_" then
         # puts "MAAAAL 7,1"
         return false
      end
      
      if filename.slice(18, 1) != "_" then
         # puts "MAAAAL 18,1"
         return false
      end
      
      # Strictly an Earth Explorer File should contain in this
      # character a "T" but some facilities work with "_"
      if filename.slice(27, 1) != "T" and filename.slice(27, 1) != "_" then
         # puts "MAAAAL 27,1"
         return false
      end

      if filename.slice(34, 1) != "_" then
         # puts "MAAAAL 34,1"
         return false
      end

      # To support AEOLUS ACMF Files with their Instance ID
      # AE_OPER_CTI_LOS____20070101T000000_0001.xml
      if filename.length == 43 then
         return true
      end

      # Strictly an Earth Explorer File should contain in this
      # character a "T" but some facilities work with "_"
      if filename.slice(43, 1) != "T" and filename.slice(27, 1) != "_" then
         # puts "MAAAAL 43,1"
         return false
      end

      if filename.slice(50, 1) != "_" then
         # puts "MAAAAL 50,1"
         return false
      end
      
      # SMOS EE File Tailoring
      if filename.length == 64 and filename.slice(0,2) == "SM" then
         if filename.slice(54, 1) != "_" then
            return false
         end

         if filename.slice(58, 1) != "_" then
            return false
         end

         if filename.slice(60, 1) != "." then
            return false
         end
         return true
      end

      # Other Files  _EX.xml (LTA Files)
      if filename.length > 59 and filename.include?("_EX.xml") == true then
         return false
      end
      return true
   end
   #-------------------------------------------------------------

   #-------------------------------------------------------------
   
   # Pass one different filename to be processed
   # - file (IN): File name
   def setFile(file)
      @filename = file
      decodeFileName(file)
   end
   #-------------------------------------------------------------
   
   # It converts when possible a numeric value to its string value.
   # (only applicable to .EEF file types).
   # i.e. : Getting FileType 1 in String Mode means getting MPL_ORBREF. 
   def setStringMode
      if @isDebugMode == true then 
         puts "EE_ReadFileName string mode set On"
      end
      @strMode = true     
   end
   #-------------------------------------------------------------
   
   # It returns when possible a numeric value instead of a string value.
   # (only applicable to .EEF file types).
   # i.e. : Getting FileType 1 instead of string MPL_ORBREF. 
   def setNumericMode
      if @isDebugMode == true then 
         puts "DCC_EE_ReadFileName string mode set Off"
      end
      @strMode = false    
   end
   #-------------------------------------------------------------
   
   # Returns File_Class
   def getFileClass
      return @fileClass
   end
   #-------------------------------------------------------------
   
   # Returns File_Type
   def getFileType
      return @fileType
   end
   #-------------------------------------------------------------
   
   # Returns Validity_Start
   def getValidityStart
      return @startValidity
   end
   #-------------------------------------------------------------   
   
   # Returns Validity_Stop
   def getValidityStop
      return @stopValidity
   end
   #-------------------------------------------------------------   

   # Returns dateStart
   def getDateStart
      return @dateStart
   end
   #-------------------------------------------------------------  
  

   # Returns dateStop
   def getDateStop
      return @dateStop
   end
   #-------------------------------------------------------------   
   
   # Returns File_Version
   def getFileVersion
      return @fileVersion
   end
   #-------------------------------------------------------------

   # Returns dateStart
   def getStrDateStart
      return @strStart
   end
   #------------------------------------------------------------- 

   # Returns dateStart
   def getStrDateStop
      return @strStop
   end
   #------------------------------------------------------------- 
   
private
   @isDebugMode        = false
   @filename           = nil
   @strMode            = false
   @getLastReturn      = nil
   
   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true   
   end
   #-------------------------------------------------------------
   
   # Decode all posible header fields from unix filename.
   # - fullname (IN): file path name
   def decodeFileName(fullname)
      filename       = File::basename(fullname)
      @fileNameType  = ""
      if File.extname(filename) == ".EEF" then
         @fileNameType = "physical"
      else
         @fileNameType = "stem"
      end
      @fileType      = filename.slice(8,10)
      @fileClass     = filename.slice(3,4)
      
      # Asign File Version
      @fileVersion   = 0

      if filename.length == 60 and File.extname(filename) == "" then
         @fileVersion   = filename.slice(55,3).to_i.to_s
      end      
      
      if filename.length == 64 and File.extname(filename).length == 4 then
         @fileVersion   = filename.slice(55,3).to_i.to_s
      end      

      if filename.length == 55 and File.extname(filename) == "" then
         @fileVersion   = filename.slice(51,4).to_i.to_s
      end      

      if filename.length == 59 and File.extname(filename).length == 4 then
         @fileVersion   = filename.slice(51,4).to_i.to_s
      end

      @strStart      = filename.slice(19,15)
      @strStop       = filename.slice(35,15)

      date = %Q{#{filename.slice(19,4)}-#{filename.slice(23,2)}-#{filename.slice(25,2)}}      
      time = %Q{#{filename.slice(28,2)}:#{filename.slice(30,2)}:#{filename.slice(32,2)}}
      @startValidity=%Q{#{date}_#{time}}
      date = %Q{#{filename.slice(35,4)}-#{filename.slice(39,2)}-#{filename.slice(41,2)}}      
      time = %Q{#{filename.slice(44,2)}:#{filename.slice(46,2)}:#{filename.slice(48,2)}}      
      @stopValidity=%Q{#{date}_#{time}}
      
      # @fileContent = filename.slice(56,3)
      @fileContent = File.extname(filename)

      # Dirty Patch again because it is forced decoding even when it is known it is not an EE File
      begin
         @start_as_dateTime = DateTime.parse(@startValidity)
#         @dateStart = Time.utc(filename.slice(19,4), filename.slice(23,2), filename.slice(25,2), filename.slice(28,2), filename.slice(30,2), filename.slice(32,2) )
         @dateStart = Time.local(filename.slice(19,4), filename.slice(23,2), filename.slice(25,2), filename.slice(28,2), filename.slice(30,2), filename.slice(32,2) )
      rescue Exception => e
         @dateStart = ""
      end

      # separate processing because of Infinite End-of-Validity Dates
      begin
         @stop_as_dateTime = DateTime.parse(@stopValidity)
#         @dateStop  = Time.utc(filename.slice(35,4), filename.slice(39,2), filename.slice(41,2), filename.slice(44,2), filename.slice(46,2), filename.slice(48,2) )
         @dateStop  = Time.local(filename.slice(35,4), filename.slice(39,2), filename.slice(41,2), filename.slice(44,2), filename.slice(46,2), filename.slice(48,2) )   
      rescue Exception => e
         @dateStop  = ""
      end
      
      if @isDebugMode == true
         puts "Decoding #{filename} :"
         puts "File Type      : #{@fileType} "
         puts "File Class     : #{@fileClass} "
         puts "File Version   : #{@fileVersion} "
         puts "Validity Start : #{@startValidity} "
         puts "Validity Stop  : #{@stopValidity} "
         puts
      end
   end
   #-------------------------------------------------------------   
   
   # Put all members with empty string
   def resetMembers
      @fileType      = ""
      @fileClass     = ""
      @fileVersion   = ""
      @startValidity = ""
      @stopValidity  = ""
      @fileContent   = ""
      @dateStart     = Time.utc("1999")
      @dateStop      = Time.utc("1999")
   end
   #-------------------------------------------------------------

end # class

end # module
