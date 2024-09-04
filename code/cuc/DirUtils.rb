#!/usr/bin/env ruby

#########################################################################
##
## === Ruby source for #DirUtils module
##
## === Written by DEIMOS Space S.L. (bolf)
##
## === Data Exchange Component -> Common Utils Component
## 
## Git: $Id: DirUtils.rb,v 1.6 2007/02/05 14:35:10 decdev Exp $
##
## Module Common Utils Component
## This module contains utility methods for handling directories
##
#########################################################################

module CUC

module DirUtils

   ## -------------------------------------------------------------
   
   ## Expand environment variable values in a path expresion
   ## - str (IN): string with a path that contains an environment variable
   def expandPathValue(str)
      bPath = true

      if str == nil then
		   return ""
		end
      
      if str[-1, 1] != "/" then
         bPath = false
      end
      
      bIsFullPath = false
      if str[0,1] == "/" then
         bIsFullPath = true
      end
      arrLevels = str.split("/")
      arrTmp    = Array.new
      arrLevels.each{|level|
         if level[0,1] == "$" then
            if ENV[level[1,level.length-1]] == nil then
               msg = "DirUtils::expandPathValue(#{str}) => Environment Variable ", level, " is not defined!"
               print msg
               print "\nCheck your configuration Files !\n\n"
               raise msg
            end
            arrTmp << ENV[level[1,level.length-1]]
         else
            arrTmp << level
         end
      }
      strPath = ""
      arrTmp.each{|level|
         if strPath == "" then
            strPath = level
         else
            strPath = %Q{#{strPath}/#{level}}
         end
      }
      if bIsFullPath == true and strPath[0,1] != "/" then
         strPath = %Q{/#{strPath}}
      end
      
      if bPath == true and strPath[-1, 1] != "/" then
         strPath = %Q{#{strPath}/}
      end
      
      return strPath
   end
   ## -------------------------------------------------------------

   ## Check directory existence. If it does not exist, create it.
   ## - dir (IN): Directory path.
   def checkDirectory(dir)
      if FileTest.exist?(dir) == false then
         cmd = %{mkdir -p #{dir}}
         retVal  = system(cmd)
         if retVal == false then
            raise "Error DirUtils::checkDirectory - #{dir}"
            # print("\n\nError DirUtils::checkDirectory ", dir, " !  :-(\n\n")
            # exit(99) 
         end
      end
   end
   ## -----------------------------------------------------------
   
   # Delete Recursively Directory without confirmation.
   # - dir (IN): Directory path.
   def deleteRecursiveDirs(dir)
      if FileTest.exist?(dir) == true then
         cmd = %{\\rm -rf #{dir}}
         retVal  = system(cmd)
         if retVal == false then
            print("\n\nError DirUtils::deleteRecursiveDirs ", dir, " !  :-(\n\n")
            exit(99) 
         end
      end
   end
   #-------------------------------------------------------------

   # Get filename Extension. 
   # It is assumed as extension the first string
   # on the right of the first "." occurrency   
   def getFileExtension(filename)
      rev = filename.reverse
      val = rev.index(".")
      # if there is no "."
      if val == nil then
         return filename
      end
      return filename.slice(filename.length-val,filename.length)
   end
   #-------------------------------------------------------------   
   
   # Get Filename without Extension. 
   # It is assumed as extension the first string
   # on the right of the first "." occurrency   
   def getFilenameWithoutExtension(filename)
      rev = filename.reverse
      val = rev.index(".")
      # if there is no "."
      if val == nil then
         return filename
      end
      return filename.slice(0,filename.length-val-1)
   end
   ## -----------------------------------------------------------
   ##
   ## Get Filename from fullPath Extension. 
   def getFilenameFromFullPath(fullPath)
      rev = fullPath.reverse
      val = rev.index("/")
      if val == nil then
         return fullPath
      end
      return fullPath.slice(fullPath.length-val,fullPath.length-1)
   end
   ## -----------------------------------------------------------
	
	# Get filenames from a given directory
	# - dir (IN): Directory path.
	# - filter (IN) : File Filters
	# It returns an array
	def getFilenamesFromDir(dir, filter)
		arrFiles = Array.new
		prevDir = Dir.pwd
		Dir.chdir(dir)
		arrFiles = Dir[filter]
      arrFiles.each{|entry|
         if FileTest.directory?(entry) == true then
            arrFiles.delete(entry)
         end
      }
		Dir.chdir(prevDir)
		return arrFiles
	end
	## -------------------------------------------------------------

   ## Expand environment variable values in a path expresion
   ## - str (IN): string with a path that might contain some code
   def generatePathValue(str)
      if str.include?("\#{") == true then
         require 'date'
         return eval(str)
      else
         return str
      end
   end
   ## -------------------------------------------------------------

end # module

end # module
