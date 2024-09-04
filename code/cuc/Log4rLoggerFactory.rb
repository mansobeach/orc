#!/usr/bin/env ruby

#########################################################################
#
# Ruby source for #Log4rLoggerFactory class
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Exchange Component -> Common Utils Component
# 
# Git:
#   $Id: Log4rLoggerFactory.rb,v 1.2 2008/07/02 10:04:07 decdev Exp $
#
#########################################################################

 # Module Common Utils Component
 # This class implements a wrapper to the log4r library.

require 'rubygems'

require 'log4r'
require 'log4r/configurator'

module CUC

class Log4rLoggerFactory

   include Log4r
   
   ### variables ###
   @configured = false
   @mainLogger = nil
   
   # Class constructor.
   # IN parameters:
   #
   # modName : string used to specify additional provenance info (eg. name of the class using this logger)
   # logConfigFile : full path and name of the log4r log-module configuration file.
   # 
   def initialize(modName = "", logConfigFile = "", isDebugMode = false)
            
      if ( logConfigFile != nil and logConfigFile.slice(0,1) == "/" ) then
         Configurator['moduleName'] = modName
         Configurator.load_xml_file(logConfigFile)
         mainLoggerName = Configurator['mainLoggerName']
         @mainLogger    = Log4r::Logger["#{mainLoggerName}"]
         # -----------------------------
         if isDebugMode == true then
            @mainLogger.level = DEBUG
            @mainLogger = Log4r::Logger["#{mainLoggerName}"].get('debug')
         end
         # -----------------------------
         @configured    = true
      end
      
   end   
   ## -----------------------------------------------------------

   def setup(modName = "", full_path_logfile = "", bLog2Syslog = false, bLog2Console = false)

      if ( modName == nil or modName == "" ) then
         @configured = false
         return false
      else
         @mainLogger = Log4r::Logger.new(modName)
         @mainLogger.level = 2 #puts main logger to INFO level
      end

      if full_path_logfile != "" and full_path_logfile != nil then
         bLog2File = true
      else
         bLog2File = false
      end

      if ( !bLog2File and !bLog2Syslog and !bLog2Console ) then
         @configured = false
         return false
      end

      logFormatter = Log4r::PatternFormatter.new(:pattern => "[%5l] %d %c - %m", :date_pattern => "%Y-%m-%d %H:%M:%S")
      
      if bLog2Console then
         @mainLogger.add Log4r::StdoutOutputter.new('console', :formatter => logFormatter)
      end

      if bLog2File then
         
#          conf = {
#             "filename" => "/tmp/pedo.log",
#             "maxsize" => 16000,
#             "trunc" => true
#          }
           
         @mainLogger.add Log4r::RollingFileOutputter.new(modName, 
               :maxsize => 500,
               :filename => "#{full_path_logfile}",
               :formatter => logFormatter,
               :trunc => true,
               :max_backups => 2,
               :maxtime => 60
               )
      end

      @configured = true
      return true

   end
   ## -----------------------------------------------------------

   def setDebugMode
      if @configured then
         @mainLogger.level = DEBUG
         return true
      else
         return false
      end
   end   
   ## -----------------------------------------------------------

   def getLogger
      if @configured then
         return @mainLogger
      else
         return nil
      end
   end
   ## -----------------------------------------------------------
   
private
   
   ## -----------------------------------------------------------
   
   ## Check that everything needed by the class is present.
   def checkModuleIntegrity
      return
   end
   ## -----------------------------------------------------------

end # class

end # module

