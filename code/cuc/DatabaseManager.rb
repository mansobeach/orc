#!/usr/bin/ruby

#########################################################################
#
# Ruby source for #DatabaseManager class
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Collector Component
# 
# CVS:
#  $Id: DatabaseManager.rb,v 1.1 2006/09/06 14:32:54 decdev Exp $
#
#########################################################################


require 'singleton'
require 'thread'
require 'Ruby9i'
require 'dbi'

 # Module Common Utils Component
 # This class handles the Ruby9i API for Oracle9i.
 #
 # It provides a method #execSQL to perform SQL operations
 # on the $ORACLE_SID database.
 #
 # This class uses the singleton package to provide only one instance of it.

module CUC

class DatabaseManager

   include Singleton
   
   #-------------------------------------------------------------
   
   # Class constructor. It is called only once as this is a singleton class
   def initialize
      @@isDebugMode       = false
      @@mutex             = Mutex.new   
      checkModuleIntegrity
      @db = Ruby9i::Database.new(@@dbName, @@dbUser, @@dbPassword)
#		@db = DBI.connect(%Q{dbi:Oracle:#{@@dbName}}, @@dbUser, @@dbPassword, 'AutoCommit' => false)
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @@isDebugMode = true
      puts "DatabaseManager debug mode is on"
   end
   #-------------------------------------------------------------
   
   # Executes the SQL sentence passed by parameter.
   # - sentence (IN): string containing the SQL literal sequence
   # It returns a Ruby9i Object Statement
   # It captures possible Exceptions from the Oracle Library.
   # Three retries are programmed in case of catching an exception.
   def execSQL(sentence)      
      @@mutex.synchronize do
         iRetries  = 0
         bExecuted = false
         if @@isDebugMode == true then
           print "exec statement : ", sentence, "\n"
         end
         while bExecuted == false
            begin
               iRetries  = iRetries + 1
               statement = @db.prepare(sentence)
               retVal    = statement.execute
               bExecuted = true
               if retVal == false then
                  print "\nError executing statement ", sentence, "\n\n"
                  return nil
               end
            rescue Exception
               puts "DataBase Error in DatabaseManager::execSQL"
               bExecuted = false
               # Wait for giving Oracle some time to free cursors
               if iRetries < 3 then
                  puts "Waiting 30 sec to retry ..."
                  sleep(30)
               else
                  puts "Fatal Error in DatabaseManager::execSQL executing"
                  puts sentence
                  exit(99)
               end
            end
	      end
         @db.commit       
         return statement
      end
   end
   #-------------------------------------------------------------
  
private

   @@isDebugMode       = false
   @@dbUser            = nil
   @@dbPassword        = nil
   @@dbName            = nil
   @db                 = nil
   @@mutex             = nil
   #-------------------------------------------------------------
   
   # Check that everything needed is present
   def checkModuleIntegrity
      
      bDefined = true
      
      if !ENV['DCC_DATABASE_USER'] then
         puts "\nDCC_DATABASE_USER environment variable not defined !\n"
         bDefined = false
      else
         @@dbUser = ENV['DCC_DATABASE_USER']      
      end
        
      if !ENV['DCC_DATABASE_PASSWORD'] then
         puts "\nDCC_DATABASE_PASSWORD environment variable not defined !\n"
         bDefined = false
      else
         @@dbPassword = ENV['DCC_DATABASE_PASSWORD']      
      end      
      
      # It shall contain "qcdb"
      if !ENV['ORACLE_SID'] then
         puts "\nORACLE_SID environment variable not defined !\n"
         bDefined = false
      else
         @@dbName = ENV['ORACLE_SID']      
      end      
 
      # Check that the Oracle Listener is running
      command = "ps -u oracle | grep tnslsnr "
      ret = `#{command}`
      if ret == "" then
        puts "\nOracle Listener is not running !!\n"
        bDefined = false
      end

      if bDefined == false then
        puts "\nError in DatabaseManager::checkModuleIntegrity :-(\n\n"
        exit(99)
      end
   end 
   #-------------------------------------------------------------

end # class

end # module

