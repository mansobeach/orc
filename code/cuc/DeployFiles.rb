#!/usr/bin/ruby

#########################################################################
#
# ===       
#
# === Written by Borja Lopez Fernandez
#
# === Casale & Beach
# 
#
#
#########################################################################

# Module Common Utils Component
# This class deploys the files specified in a list
# Files are appended $DEC_BASE as root directory 

module CUC

class DeployFiles

   #-------------------------------------------------------------
   
   # Class constructor.
   # IN parameters:
   # * string - full path filename of the list of files to be deployed
   def initialize(fullPathFilename, debugMode = false)
      @fileList      = fullPathFilename
      @isDebugMode   = debugMode
      
      checkModuleIntegrity
      
      init
   end
   #-------------------------------------------------------------

   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode  = true
      puts "DeployFiles debug mode is on"
   end
   #-------------------------------------------------------------

   def getListofFiles
      return @arrFilesToBeDeployed
   end
   #-------------------------------------------------------------

private
   
   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      
      if !ENV['DEC_BASE'] then
         puts "\nDEC_BASE environment variable not defined !\n"
         bDefined = false
      else
         @rootDir = ENV['DEC_BASE']
      end
      
      
      if bDefined == false then
         puts "\nError in DeployFiles::checkModuleIntegrity :-(\n\n"
         exit(99)
      end
   end
   #-------------------------------------------------------------
   
   def init
      @arrFilesToBeDeployed = Array.new
   
      file     = File.new(@fileList, "r")
      arrLines = file.readlines

      arrLines.each{|line|
         if line.to_s.slice(0,1) == "#" or line.to_s.strip.length == 0 then
            if @isDebugMode == true then
               puts "skip line #{line}"
            end
            next
         end
         
         aFile = "#{@rootDir}/#{line}"
         @arrFilesToBeDeployed << aFile
      }

   end
   #-------------------------------------------------------------
   
end # class

end # module
