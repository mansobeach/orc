#!/usr/bin/ruby

#########################################################################
#
# Ruby source for #Logger class
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Exchange Component -> Common Utils Component
# 
# CVS:
#   $Id: DEC_Logger.rb,v 1.1 2006/09/06 14:32:54 decdev Exp $
#
#########################################################################

 # Module Common Utils Component
 # This class implements the DEC File Logger.

require 'cuc/Logger'
require 'cuc/DirUtils'

module CUC

class DEC_Logger < Logger

   include CUC
   include DirUtils
   #-------------------------------------------------------------
   
   # Class constructor.
   # IN parameters:
   # * string - full path filename of the log.
   # * bool   - register time for each entry   
   def initialize(header = "")
      checkModuleIntegrity
      super(@fileLog, true, header)
   end   
   #-------------------------------------------------------------
   
private
   
   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      
      if !ENV['DCC_TMP'] then
         puts "\nDCC_TMP environment variable not defined !\n"
         bDefined = false
      end

      @tmpDir   = ENV['DCC_TMP']
      checkDirectory(@tmpDir)
      
      @fileLog = %Q{#{@tmpDir}/dec_log.txt}
      
      if bDefined == false then
         puts "\nError in CheckerProcessUniqueness::DEC_Logger :-(\n\n"
         exit(99)
      end
   end
   #-------------------------------------------------------------

end # class

end # module

