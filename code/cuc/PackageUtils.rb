#!/usr/bin/ruby

#########################################################################
##
## Ruby source for #PackageUtils class
##
## Fullfils FTR-1.10 Requirement (CS-RS-ESA-GS-0212)
##
## Written by DEIMOS Space S.L. (bolf)
##
## Data Exchange Component -> Common Utils Component
## 
## Git:
##  $Id: PackageUtils.rb,v 1.3 2007/11/30 10:57:22 decdev Exp $
##
#########################################################################

require 'fileutils'

require 'cuc/DirUtils'

# Module Common Utils Component
# This module contains utility methods for Packing / UnPacking
# through external compressors
# Supported tools are: TAR, ZIP, GZIP, COMPRESS

module CUC

module PackageUtils

   include CUC::DirUtils
   # include FileUtils::NoWrite
   include FileUtils 
   
   CompressMethods = ["NONE", "7Z", "TGZ", "ZIP", "TAR", "GZIP", "COMPRESS", "UNPACK", "UNPACK_HDR", "UNPACK_DBL"]
    
   ## --------------------------------------------------------------

   ## compress a single file into ZIP
   ##
   ## - full_path_file   (IN): File to be compressed
   ## - deleteSourceFile (IN): Flag to delete the source file
   def packZIP(full_path_file, bDeleteSourceFile=true)
      checkModuleIntegrity
      if FileTest.exist?(full_path_file) == false then
         return false
      end
      fileName   = File.basename(full_path_file)
      fileTarget = File.basename(full_path_file, ".*")
      fileTarget = "#{fileTarget}.ZIP"
      dirName    = File.dirname(full_path_file)
      prevDir    = Dir.pwd
      checkDirectory(@localDir)
      copy_file(full_path_file, "#{@localDir}/#{fileName}")
      Dir.chdir(@localDir)
      
      cmd       = %Q{zip #{fileTarget} #{fileName}}
      `#{cmd}`
      
      copy_file(fileTarget, "#{dirName}/#{fileTarget}")
      remove_file(fileTarget, true)
      remove_file(fileName, true)
      Dir.chdir(dirName)
      if bDeleteSourceFile == true then
         File.delete(fileName)
      end
      Dir.chdir(prevDir)
      remove_dir(@localDir, true)
   end
   ## -----------------------------------------------------------

   ## uncompress 7z file
   ##
   ## - full_path_file   (IN): File to be compressed
   ## - deleteSourceFile (IN): Flag to delete the source file
   ##
   ## Silent compression
   ## https://serverfault.com/questions/108024/silent-7za-compression
   
   def unpack7z( full_path_file, \
               destination_path, \
               bDeleteSourceFile = true, \
               bIsDebugMode = false, \
               logger = nil \
               )
      checkModuleIntegrity
      
      if FileTest.exist?(full_path_file) == false then
         return false
      end

      # cmd  = %Q{7za x #{full_path_file} -o#{File.dirname(full_path_file)}}
      cmd  = %Q{7za e #{full_path_file} -o#{destination_path} -aoa }

      ## silent mode
      ## > progress redirected to 0
      ## > output redirected to 0
      if bIsDebugMode == false then
         cmd = "#{cmd} -y -bsp0 -bso0"
      end

      if bIsDebugMode == true and logger != nil then
         logger.debug(cmd)
      end

      retVal = system(cmd)

      if retVal == true and bDeleteSourceFile == true then
         FileUtils::rm_f(full_path_file)
      end

      return retVal

   end
   ## -----------------------------------------------------------

   ## compress a single file into 7z
   ##
   ## - full_path_file   (IN): File to be compressed
   ## - deleteSourceFile (IN): Flag to delete the source file
   ##
   ## Silent compression
   ## https://serverfault.com/questions/108024/silent-7za-compression
   
   
   def pack7z( full_path_file, \
               targetName = "", \
               bDeleteSourceFile = true, \
               bIsDebugMode = false, \
               logger = nil \
               )
            
      checkModuleIntegrity
      
      if FileTest.exist?(full_path_file) == false then
         return false
      end

      if targetName == "" then
         targetName = File.basename(full_path_file, ".*")
         targetName = "#{targetName}.7z"
      end

      bIsDir = true

      cmd  = %Q{7za a #{targetName} #{full_path_file}}

      ## silent mode
      ## > progress redirected to 0
      ## > output redirected to 0
      if bIsDebugMode == false then
         cmd = "#{cmd} -y -bsp0 -bso0"
      end

      if FileTest.directory?(full_path_file) == true then
         cmd  = %Q{#{cmd}/*}
      end

#      if bDeleteSourceFile == true then
#         cmd = "#{cmd} -sdel"
#      end

      if bIsDebugMode == true and logger != nil then
         logger.debug(cmd)
      end

      retVal = system(cmd)

#       if retVal == false then
#          File.delete(targetName)
#       end

      if retVal == true and bDeleteSourceFile == true then
         FileUtils::rm_f(full_path_file)
      end

      return retVal
   end
   ## -----------------------------------------------------------
   
   def initialize(file, path, bDeleteSrc)
     @isModuleOK        = false
     @isModuleChecked   = false
     @isDebugMode       = false
     @compressMethod    = ""
     @bDeleteSrc        = bDeleteSrc
     @srcFile           = file
     @srcPath           = path
     checkModuleIntegrity
     
     @fullpathFile = %Q{#{@srcPath}/#{@srcFile}}
     
     if FileTest.exist?(@fullpathFile) == false then
        puts "Internal Error PackageUtils::initialize =:-0 !!!"
        puts "#{@fullpathFile} does not exist !"
        exit(99)
     end       
   end
   #-------------------------------------------------------------
   
   # Unpack file -> can generate from 1 to n files
   def unpack   
      ext = getFileExtension(@srcFile)
      if @isDebugMode == true then
         puts "Unpacking filetype #{ext}"
      end
            
      if isValidCompressMethod(ext) == false then
         if @isDebugMethod == true then
            puts "#{ext} is not a valid Unpacking method !"
         end
         return false
      end
      performUnpack(ext)
   end   
   #-------------------------------------------------------------

   def setCompressMethod(method)
      if isValidCompressMethod(method) == true then
         @compressMethod = method
         return true
      end
      @compressMethod = ""
      return false
   end
   #-------------------------------------------------------------

   def isValidCompressMethod(method)
      bRet = nil
      case method.upcase   
         when "TGZ"    then bRet = true
         when "ZIP"    then bRet = true
         when "GZIP"   then bRet = true
         else
            bRet = false  
      end
      return bRet
   end
   #-------------------------------------------------------------   
   
   #
   def pack
      case @compressMethod
         when "TGZ"    then bRet = performTGZ
         when "ZIP"    then bRet = performZip
         when "GZIP"   then bRet = performGzip
         else
            bRet = false  
      end
   end
   #-------------------------------------------------------------

   # Get package and  return a list with all files into the packed file.
   def getPackageContent
      extension=getFileExtension(@srcFile)
      cmd=""
      case extension
         when "TGZ"    then cmd = "tar tzf    #@fullpathFile"
         when "ZIP"    then cmd = "unzip -lqq #@fullpathFile"
         when "GZ"     then cmd = "gunzip -lqN #@fullpathFile"
      end
      out = IO.popen(cmd, "w+")
      list = out.readlines
      out.close_write
      return list
   end


   # Check package content file names 
   # - If the package has one file, then this file must have extension EEF
   # - If the package has two files, it must contain a header file with 
   # extension HDR and data block file with extension DBL
   #
   # Return
   #   - true, if package content is correct
   #   - false, otherwise
   def checkPackageContent
      #return a list of files into the package.
      list = getPackageContent
      #if list.size=0 is a not packed file.
      if list.size!=0 then
         # Check package name vs. package content file names
         list.each {|file|
            name=getFilenameWithoutExtension(file)
            namePackage=getFilenameWithoutExtension(@srcFile)
            pos=name.size-namePackage.size
            nameFilePackage=name[pos,name.size]
            if nameFilePackage!=namePackage then
               return false
            end
         }
         # Check package content extensions
         case list.size
            when 1 then   
               ext=getFileExtension(list[0]).chop
               if ( ext == "EEF" ) then
                  return true
               end
                       
            when 2 then   
               ext1=getFileExtension(list[0]).chop
               ext2=getFileExtension(list[1]).chop
               if ((( ext1 == "HDR" ) and ( ext2 == "DBL" )) or
                   (( ext2 == "HDR" ) and ( ext1 == "DBL" ))) then 
                  return true
               end
         end
      end
      #Package does not contain correct file names.
      return false
   end

   def isPackage
      extension=getFileExtension(@srcFile)
      case extension
         when "TGZ"    then return true
         when "ZIP"    then return true
         when "GZ"     then return true
         else return false
      end
    
   end
   #-------------------------------------------------------------
   # Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "PackageUtils Debug Mode is on !"
   end
   #-------------------------------------------------------------

private

   @isModuleOK        = false
   @isModuleChecked   = false
   @isDebugMode       = false      

   #-------------------------------------------------------------

   # Check that UNIX commands for the supported pack/unpack
   # tools are in the $PATH
   def checkModuleIntegrity
      puts "PackageUtils::checkModuleIntegrity"
      bDefined = true
          
     #      # check UNIX compress tool
     #      isToolPresent = `which compress`
     #    
     #      if isToolPresent[0,1] != '/' then
     #        puts "\n\nPackageUtils::checkModuleIntegrity\n"
     #        puts "Fatal Error: compress not present in PATH !!   :-(\n\n\n"
     #        exit(-1)
     #      end
          
      #check gzip tool
      isToolPresent = `which gzip`
   
      if isToolPresent[0,1] != '/' or $? != 0 then
         puts "\n\nPackageUtils::checkModuleIntegrity\n"
         puts "Fatal Error: gzip not present in PATH !!   :-(\n\n\n"
         exit(99)
      end     
          
      #check zip tool
      isToolPresent = `which zip`
   
      if isToolPresent[0,1] != '/' or $? != 0 then
         puts "\n\nPackageUtils::checkModuleIntegrity\n"
         puts "Fatal Error: zip not present in PATH !!   :-(\n\n\n"
         bDefined = false
      end     
          
      #check unzip tool
      isToolPresent = `which unzip`
   
      if isToolPresent[0,1] != '/' or $? != 0 then
         puts "\n\nPackageUtils::checkModuleIntegrity\n"
         puts "Fatal Error: unzip not present in PATH !!   :-(\n\n\n"
         bDefined = false
      end          

      #check tar tool
      isToolPresent = `which tar`
   
      if isToolPresent[0,1] != '/' or $? != 0 then
         puts "\n\nPackageUtils::checkModuleIntegrity\n"
         puts "Fatal Error: tar not present in PATH !!   :-(\n\n\n"
         bDefined = false
      end
     
      #check 7z tool
      isToolPresent = `which 7za`
   
      if isToolPresent[0,1] != '/' or $? != 0 then
         puts "\n\nPackageUtils::checkModuleIntegrity\n"
         puts "Fatal Error: 7za not present in PATH !!   :-(\n\n\n"
         bDefined = false
      end
     
      if bDefined == false then
         puts "\nError in Packageutils::checkModuleIntegrity :-(\n\n"
         exit(99)
      end     
     
      time      = Time.new
      str       = time.strftime("%Y%m%d_%H%M%S")                                     
      @localDir = %Q{/tmp/.#{str}_packager}               
   end
   #------------------------------------------------------------- 
   
   def performUnpack(compressMethod)
      case compressMethod.upcase
         when "TGZ"    then bRet = performUnTGZ
         when "ZIP"    then bRet = performUnZip
         when "GZIP"   then bRet = performUnGzip
         else
            bRet = false  
      end
   end   
   #-------------------------------------------------------------

   def performUnzip
      prevDir = Dir.pwd
      Dir.chdir(@srcPath)
      cmd     = %Q{unzip #{@srcFile}}
      if @isDebugMode == true then
         puts cmd
      end
      `#{cmd}` 
      if @bDeleteSrc == true then
         File.delete(@srcFile)
      end      
      Dir.chdir(prevDir)   
   end
   #-------------------------------------------------------------

   def performUnGzip
      prevDir = Dir.pwd
      Dir.chdir(@srcPath)
      cmd     = %Q{gzip -d -N #{@srcFile}}
      if @isDebugMode == true then
         puts cmd
      end
      `#{cmd}` 
      Dir.chdir(prevDir)   
   end
   #-------------------------------------------------------------

   # 
   def performZip
      prevDir = Dir.pwd
      Dir.chdir(@srcPath)
      filname = getFilenameWithoutExtension(@srcFile)
      cmd     = %Q{zip #{filname}.ZIP #{@srcFile}}
      if @isDebugMode == true then
         puts cmd
      end 
      `#{cmd}`
      if @bDeleteSrc == true then
         File.delete(@srcFile)
      end    
      Dir.chdir(prevDir)
      return %Q{#{filname}.ZIP}                
   end
   #-------------------------------------------------------------
   
   def performGzip
      filname = getFilenameWithoutExtension(@srcFile)
      prevDir = Dir.pwd
      Dir.chdir(@srcPath)
      cmd     = %Q{gzip -N #{@srcFile}}
      if @isDebugMode == true then
         puts cmd
      end 
      `#{cmd}`
      cmd     = %Q{mv #{@srcFile}.gz #{filname}.GZ}
      system(cmd)   
      Dir.chdir(prevDir)
      return %Q{#{filname}.GZ}
   end
   #-------------------------------------------------------------

   # Not implemented
   def performCompress
      puts "compress funcionality not available"
      exit(99)
   end
   #------------------------------------------------------------
   #-------------------------------------------------------------
   
   #
   def performTGZ
      filname = getFilenameWithoutExtension(@srcFile)
      kk      = filname
      filname = %Q{#{filname}.TAR}
      executeTar(@srcFile, filname)
      newName = executeGzip(filname)
      prevDir = Dir.pwd
      Dir.chdir(@srcPath)
      cmd = %Q{mv #{newName} #{kk}.TGZ}
      if @isDebugMode == true then
         puts cmd
      end 
      `#{cmd}`
      if @bDeleteSrc == true and (FileTest.exist?(@srcFile) == true) then
         File.delete(@srcFile)
      end
      Dir.chdir(prevDir)
      return %Q{#{kk}.TGZ}
   end
   #-------------------------------------------------------------
   
   def performUnTGZ
      prevDir = Dir.pwd
      Dir.chdir(@srcPath)
      cmd     = %Q{tar xvfz #{@srcFile}}
      if @isDebugMode == true then
         puts cmd
      end 
      `#{cmd}`
      if @bDeleteSrc == true then
         File.delete(@srcFile)
      end      
      Dir.chdir(prevDir)
      return
   end
   #-------------------------------------------------------------
   
   # executes TAR 
   def executeTar(srcName, targetName)
      prevDir = Dir.pwd
      Dir.chdir(@srcPath)
      cmd     = %Q{tar cvf #{targetName} #{srcName}}
      if @isDebugMode == true then
         puts cmd
      end 
      `#{cmd}`
      Dir.chdir(prevDir)
      return targetName
   end
   #-------------------------------------------------------------
   
   def executeGzip(filename=@srcFile)
      prevDir = Dir.pwd
      Dir.chdir(@srcPath)
      filname = getFilenameWithoutExtension(filename)
      cmd     = %Q{gzip #{filename}}
      if @isDebugMode == true then
         puts cmd
      end
      `#{cmd}`
      
      if @bDeleteSrc == true and (FileTest.exist?(@srcFile) == true) then
         File.delete(@srcFile)
      end
      
      cmd = %Q{mv #{filename}.gz #{filename}.GZ}      
      if @isDebugMode == true
         puts cmd
      end      
      `#{cmd}`

      Dir.chdir(prevDir)
      return %Q{#{filename}.GZ}
   end
   #------------------------------------------------------------- 
   
   #=============================================================
end # module PackageUtils

end # module CUC
