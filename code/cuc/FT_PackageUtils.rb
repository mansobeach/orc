#!/usr/bin/env ruby

#########################################################################
#
# Ruby source for #FT_PackageUtils class
#
# Fullfils FTR-1.10 Requirement (CS-RS-ESA-GS-0212)
#
# Written by DEIMOS Space S.L. (bolf)
#
# RPF
# 
# CVS:
#  $Id: FT_PackageUtils.rb,v 1.10 2008/08/13 14:59:28 decdev Exp $
#
#########################################################################

require 'fileutils'

require 'cuc/DirUtils'

class FT_PackageUtils

   attr_reader :CompressMethods, :newfilename
   
   CompressMethods = [  "NONE", \
                        "Z", \
                        "7Z", \
                        "TGZ", \
                        "ZIP", \
                        "TAR", \
                        "GZIP", \
                        "COMPRESS", \
                        "UNPACK", \
                        "UNPACK_HDR", \
                        "UNPACK_DBL"]

   include CUC::DirUtils

   include FileUtils::NoWrite
    
   ## --------------------------------------------------------------

   ## Class constructor.
   ##
   ## - file (IN): File basename
   ## - path (IN): File directory
   ## - bDeleteSrc (IN): flag for deleting source file
   def initialize(file, path, bDeleteSrc)
     @isModuleOK        = false
     @isModuleChecked   = false
     @isDebugMode       = false
     @compressMethod    = ""
     @bDeleteSrc        = bDeleteSrc
     @srcFile           = file
     @newfilename       = file
     @srcPath           = path
     checkModuleIntegrity
     
     @fullpathFile = %Q{#{@srcPath}/#{@srcFile}}
     
     if FileTest.exist?(@fullpathFile) == false then
        puts "Internal Error FT_PackageUtils::initialize =:-0 !!!"
        puts "#{@fullpathFile} does not exist !"
        exit(99)
     end       
   end
   ## -------------------------------------------------------------
   
   def decompress
   
   end
   ## -------------------------------------------------------------
   
   ## Unpack file -> it can generate from 1 to n files
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
      return performUnpack(ext)
   end   
   ## -----------------------------------------------------------

   def setCompressMethod(method)
      if isValidCompressMethod(method) == true then
         @compressMethod = method
         return true
      end
      @compressMethod = ""
      return false
   end
   ## -----------------------------------------------------------

   def isValidCompressMethod(method)
      bRet = nil
      case method.upcase
         when "TAR"        then bRet = true   
         when "TGZ"        then bRet = true
         when "ZIP"        then bRet = true
         when "GZIP"       then bRet = true
         when "7Z"         then bRet = true
         when "NONE"       then bRet = true
         when "UNPACK"     then bRet = true
         when "UNPACK_HDR" then bRet = true
         when "UNPACK_DBL" then bRet = true
         when "Z"          then bRet = true
         else
            bRet = false  
      end
      return bRet
   end
   ## -------------------------------------------------------------   
   
   ##
   def pack
      #puts "FT_PackageUtils::pack(#{@compressMethod})"
      case @compressMethod
         when "7Z"         then bRet = perform7z
         when "TGZ"        then bRet = performTGZ
         when "ZIP"        then bRet = performZip
         when "GZIP"       then bRet = performGzip
         when "NONE"       then bRet = performNone
         when "UNPACK"     then bRet = unpack
         when "UNPACK_HDR" then bRet = performUnpackHDR
         when "UNPACK_DBL" then bRet = performUnpackDBL
         else
            bRet = false  
      end
   end
   ## -------------------------------------------------------------

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
         when "TAR"    then return true
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
      puts "FT_PackageUtils Debug Mode is on !"
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

#      if !ENV.include?('DCC_TMP') and !ENV.include?('DEC_TMP') and !ENV.include?('ORC_TMP') then
#         puts "\nDCC_TMP | DEC_TMP | ORC_TMP environment variable not defined !\n"
#         bDefined = false
#      end      
          
     #      # check UNIX compress tool
     #      isToolPresent = `which compress`
     #    
     #      if isToolPresent[0,1] != '/' then
     #        puts "\n\nFT_PackageUtils::checkModuleIntegrity\n"
     #        puts "Fatal Error: compress not present in PATH !!   :-(\n\n\n"
     #        exit(-1)
     #      end
          
     #check gzip tool
     isToolPresent = `which gzip`
   
     if isToolPresent[0,1] != '/' then
       puts "\n\nFT_PackageUtils::checkModuleIntegrity\n"
       puts "Fatal Error: gzip not present in PATH !!   :-(\n\n\n"
       bDefined = fase
     end     
          
     #check zip tool
     isToolPresent = `which zip`
   
     if isToolPresent[0,1] != '/' then
       puts "\n\nFT_PackageUtils::checkModuleIntegrity\n"
       puts "Fatal Error: zip not present in PATH !!   :-(\n\n\n"
       bDefined = fase
     end     
          
     #check unzip tool
     isToolPresent = `which unzip`
   
     if isToolPresent[0,1] != '/' then
       puts "\n\nFT_PackageUtils::checkModuleIntegrity\n"
       puts "Fatal Error: unzip not present in PATH !!   :-(\n\n\n"
       bDefined = fase
     end          

     #check tar tool
     isToolPresent = `which tar`
   
     if isToolPresent[0,1] != '/' then
       puts "\n\nFT_PackageUtils::checkModuleIntegrity\n"
       puts "Fatal Error: tar not present in PATH !!   :-(\n\n\n"
       bDefined = fase
     end

     #check 7za tool
     isToolPresent = `which 7za`
   
     if isToolPresent[0,1] != '/' then
       puts "\n\nFT_PackageUtils::checkModuleIntegrity\n"
       puts "Fatal Error: 7za not present in PATH !!   :-(\n\n\n"
       bDefined = fase
     end

     
     if bDefined == false then
        puts "\nError in FT_Packageutils::checkModuleIntegrity :-(\n\n"
        exit(99)
     end     
     
     time      = Time.new
     str       = time.strftime("%Y%m%d_%H%M%S")
     
#     configDir = nil
#
#      if ENV['DEC_CONFIG'] then
#         configDir         = %Q{#{ENV['DEC_CONFIG']}}  
#      else
#         configDir         = %Q{#{ENV['DCC_CONFIG']}}  
#      end
#                                     
#     @localDir = %Q{#{configDir}/.#{str}_packager}                 
   end
   
   ## ----------------------------------------------------------- 
   
   ## ----------------------------------------------------------- 
   
   def performUnpack(compressMethod)
      case compressMethod.upcase
         when "Z"      then bRet = performUncompress
         when "TAR"    then bRet = performUnTar 
         when "TGZ"    then bRet = performUnTGZ
         when "ZIP"    then bRet = performUnZip
         when "GZIP"   then bRet = performUnGzip
         when "7Z"     then bRet = performUncompress7z
         else
            puts "Unpack method #{compressMethod} is not supported"
            bRet = false  
      end
   end   
   ## -----------------------------------------------------------

   def performUnpackHDR
      bRet = unpack
 
      prevDir = Dir.pwd
      Dir.chdir(@srcPath)

      baseName = File.basename(@srcFile, ".*")
      baseName = %Q{#{baseName}*}
      arrFiles = Dir[baseName]

      arrFiles.each{|aFile|
         if File.extname(aFile) == ".DBL" then
            File.delete(aFile)
         end
      }

      Dir.chdir(prevDir)
        
   end
   #-------------------------------------------------------------

   def performUnpackDBL
      bRet = unpack
 
      prevDir = Dir.pwd
      Dir.chdir(@srcPath)

      baseName = File.basename(@srcFile, ".*")
      baseName = %Q{#{baseName}*}
      arrFiles = Dir[baseName]

      arrFiles.each{|aFile|
         if File.extname(aFile) == ".HDR" then
            File.delete(aFile)
         end
      }

      Dir.chdir(prevDir)    
   end
   ## -----------------------------------------------------------

   def performUncompress
      cmd     = %Q{uncompress -f #{@fullpathFile}}
      if @isDebugMode == true then
         puts cmd
      end
      `#{cmd}`    
   end
   ## -----------------------------------------------------------
   
   def performUnZip
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
   ## -----------------------------------------------------------

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
      cmd     = %Q{zip -r #{filname}.ZIP #{@srcFile}}
      if @isDebugMode == true then
         puts cmd
      end 
      `#{cmd}`
      if @bDeleteSrc == true then
         FileUtils.rm_rf(@srcFile)
      end    
      Dir.chdir(prevDir)
      return %Q{#{filname}.ZIP}                
   end
   #-------------------------------------------------------------
   
   def performNone
      filname = File.basename(@srcFile)
      return filname
   end
   #-------------------------------------------------------------
   
   def performUncompress7z
      prevDir = Dir.pwd
      Dir.chdir(@srcPath)
      cmd     = %Q{7za x -y #{@srcFile}}
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

   def performUnTar
      prevDir = Dir.pwd
      Dir.chdir(@srcPath)
      cmd     = %Q{tar xvf #{@srcFile}}
      if @isDebugMode == true then
         puts cmd
      end 
      ret = `#{cmd}`
      arr = ret.split("\n")

      if @bDeleteSrc == true then
         File.delete(@srcFile)
      end      
      Dir.chdir(prevDir)
      return arr
   end
   #-------------------------------------------------------------   
   
   def performUnTGZ
      prevDir = Dir.pwd
      Dir.chdir(@srcPath)
      cmd     = %Q{tar xvfz #{@srcFile}}
      if @isDebugMode == true then
         puts cmd
      end 
      ret = `#{cmd}`
      arr = ret.split("\n")

      if @bDeleteSrc == true then
         File.delete(@srcFile)
      end      
      Dir.chdir(prevDir)
      return arr
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
   
   ## -------------------------------------------------------------
   
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
   ## ------------------------------------------------------------- 
   
   ## --------------------------------------------------------------

   ## compress a single file into 7z
   ##
   ## - full_path_file   (IN): File to be compressed
   ## - deleteSourceFile (IN): Flag to delete the source file
   
   def perform7z(filename=@srcFile)
      prevDir = Dir.pwd
      Dir.chdir(@srcPath)
            
      @newfilename = "#{getFilenameWithoutExtension(@srcFile)}.7z"

      if FileTest.directory?(@srcFile) == true then
         cmd  = %Q{7za a #{@newfilename} #{@fullpathFile}/*}
      else
         cmd  = %Q{7za a #{@newfilename} #{@fullpathFile}}
      end

      ## silent mode
      ## > progress redirected to 0
      ## > output redirected to 0
      if @isDebugMode == false then
         cmd = "#{cmd} -y -bsp0 -bso0"
      end

#      if bDeleteSourceFile == true then
#         cmd = "#{cmd} -sdel"
#      end

      if @isDebugMode == true then
         puts(cmd)
      end

      retVal = system(cmd)

      if retVal == true then
         FileUtils.rm_f(filename)
      else
         puts "Failed FT_PackageUtils::pack7z"
         puts
      end

      Dir.chdir(prevDir)
      return retVal
   end  
   ## -------------------------------------------------------------
   
end
