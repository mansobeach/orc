#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #Wrapper_md5sum class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component (DEC)
### 
### Git: Wrapper_md5sum,v $Id$ $Date$
###
### module CUC
###
#########################################################################

require 'rubygems'
require 'date'
require 'cuc/Converters'

module CUC

class WrapperMD5SUM

   include CUC::Converters

   ## ------------------------------------------------  
   
   ## Class contructor
   ## 
   def initialize(fullpathfile, debugMode = false)
      @fullpathfile        = fullpathfile
      @isDebugMode         = debugMode
      checkModuleIntegrity
      @cmd                 = "md5sum \"#{@fullpathfile}\""
      @result              = `#{@cmd}`
      if @isDebugMode == true then
         puts @cmd
         puts @result
      end
   end
   ## ------------------------------------------------
   
   ## Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "WrapperMD5SUM debug mode is on"
   end
   ## ------------------------------------------------

   def md5
      return @result.split(" ")[0]
   end
   ## ------------------------------------------------

private

   # -------------------------------------------------------------
   # Check that everything needed by the class is present.
   # -------------------------------------------------------------
   def checkModuleIntegrity
      return
   end
   # --------------------------------------------------------
   
end # class

end # module
