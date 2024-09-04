#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #CheckerProcessUniqueness class
###
### === Written by DEIMOS Space S.L.
###
### === Data Exchange Component -> Common Utils Component
###
### Git: $Id: CheckerProcessUniqueness.rb,v 1.3 2007/09/04 04:09:43 decdev Exp $
###
###
###
#########################################################################

require 'cuc/DirUtils'

 # Module Common Utils Component
 # This class checks whether a given process name is already running
 # or not.
 #
 # It registers the process which is going to
 # run in a "lock" temp file, which contains its PID.
 # The name of the lock process file is conformed with the process name
 # and an optional argument if we want to allow different
 # instances of the same process running.
 #
 # Lock File for each process name contains:
 # * PID\n
 #
 # The method setRunning MUST be invoked in the Target process.
 # This is done because this class extracts the PID from the current Process.
 #

module CUC

class CheckerProcessUniqueness

   include CUC
   include DirUtils
   ## -----------------------------------------------------------

   # Class constructor.
   # IN Parameters:
   # * string: the name of the process.
   # * string: optional arguments used by the process.
   # * boolean: if it is interpreted with ruby.
   # * string: temporal directory for the lock files
   def initialize(processName, args, isRubyInterpreted, tmpDir = nil)
      @isDebugMode = false
      @processName = processName
      @isRuby      = isRubyInterpreted
      @args        = args
      @tmpDir      = tmpDir
      checkModuleIntegrity
   end
   ## -----------------------------------------------------------

   ## Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "CheckerProcessUniqueness debug mode is on"
   end
   ## ------------------------------------------------------------

   ## Checks if the process is already running.
   ## * Returns True if it is running.
   ## * Returns False if its not.
   def isRunning

      if @isDebugMode == true then
         puts "CheckerProcessUniqueness::isRunning => file lock #{@fileLock}"
      end

      if FileTest.exist?(@fileLock) == false then
         return false
      end

      @pid = readPID

      if @pid == false then
         return false
      end
      return checkProcess(@pid)
   end
   ## -----------------------------------------------------------

   ## It returns the running PID of the process if avalaible.
   ## Otherwise it returns false.
   ## * Returns PID number of the process if it is running.
   ## * Returns False if its not.
   def getRunningPID

	   # for getting the running PID, wait some seconds to give
      # time the process to be registered
      sleep(2)

      if FileTest.exist?(@fileLock) == false then
         return false
         raise "CheckerProcessUniqueness::getRunningPID File Lock process #{@fileLock} does not exist"
      end

      pid = readPID

      if pid == false then
         return false
         raise "CheckerProcessUniqueness::getRunningPID File Lock process #{@fileLock} does not exist"
      end

      if checkProcess(pid) == true then
         return pid
      else
         return false
      end
   end
   ## -------------------------------------------------------------

   ## It registers current Process in the Lock File.
   ## It writes in the lock file the current PID.
   def setRunning
      writePID
   end
   ##-------------------------------------------------------------

   ## Remove lock file.
   ## This method must be invoked from the process just before
   ## finishing
   def release
      if FileTest.exist?(@fileLock) == true then
         File.delete(@fileLock)
      end
   end
   ## -----------------------------------------------------------

	# it kills the given process
   def kill
      pid = getRunningPID
      if pid == false then
         return false
      end
      Process.kill(9, pid.to_i)
      release
      return true
   end
   #-------------------------------------------------------------

   # It registers an external Process in the Lock File.
   # It writes in the lock file the given PID.
   def setExternalProcessRunning(pid)
      writePID(pid)
   end
   ## -----------------------------------------------------------

   def getAllRunningProcesses(excludePattern = "")
      command  = ""
      if excludePattern == "" then
         command  = %Q{ps -ef | grep #{@processName} | grep -v grep }
      else
         command  = %Q{ps -ef | grep #{@processName} | grep -v #{excludePattern} | grep -v grep }
      end
      retVal   = `#{command}`
      if @isDebugMode == true then
         puts "\n#{command}\n"
         puts
         puts "#{retVal}\n"
      end
      arrPids = Array.new
      retVal.split("\n").each{|aProcess|
         arrPids << aProcess.split(" ")[1]
      }
      return arrPids.uniq
   end
   ## -----------------------------------------------------------


private

   ## -----------------------------------------------------------

   ## Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true

      if !ENV.include?('DCC_TMP') and !ENV.include?('DEC_TMP') and !ENV.include?('ORC_TMP') and @tmpDir == nil then
         puts "\nDCC_TMP | DEC_TMP | ORC_TMP environment variable not defined !\n"
         bDefined = false
      end

      if bDefined == false and @tmpDir == nil then
         puts "\nError in CheckerProcessUniqueness::checkModuleIntegrity :-(\n\n"
         exit(99)
      end

      if @tmpDir == nil then

         if ENV.include?('DCC_TMP') then
            @tmpDir   = ENV['DCC_TMP']
         end

         if ENV.include?('DEC_TMP') then
            @tmpDir   = ENV['DEC_TMP']
         end

         if ENV.include?('ORC_TMP') then
            @tmpDir   = ENV['ORC_TMP']
         end

         if ENV.include?('MINARC_TMP') then
            @tmpDir   = ENV['MINARC_TMP']
         end

         if @tmpDir == nil then
            raise "CheckerProcessUniqueness::checkModuleIntegrity failed to obtain tmp dir"
         end

      end

      checkDirectory(@tmpDir)

      if @args == nil then
        @fileLock = %Q{#{@tmpDir}/.lock_#{@processName}}
      else
        @fileLock = %Q{#{@tmpDir}/.lock_#{@processName}_#{@args.delete("/").delete(" ")}}
        # \""
      end
   end
   ## -----------------------------------------------------------

   # It reads the File Lock of a given process name to check
   # the last PID registered to watch if it is still running.
   # * It returns the PID from the File if successful.
   # * Otherwise it returns false.
   def readPID
      if @isDebugMode == true then
         puts "file lock #{@fileLock}"
      end
      if FileTest.exist?(@fileLock) == false then
         return false
      end
      aFile = nil
      aFile = File.new(@fileLock, "r")
      begin
         pid   = aFile.readline
      rescue Exception => e
         puts e.to_s
         return false
      end
      if @isDebugMode == true then
         puts "PID get from #{@fileLock} is #{pid}"
      end
      return pid.chop
   end
   ## -----------------------------------------------------------

   ## It writes the File Lock with the new PID.
   ## If a previous File Lock existed, it is deleted.
   def writePID(extpid = -1)
	   pid = nil
      if FileTest.exist?(@fileLock) == true then
         File.delete(@fileLock)
      end
      if extpid == -1 then
         pid = Process.pid.to_s
      else
         pid = extpid.to_s
      end
      aFile = nil
      aFile = File.new(@fileLock, File::CREAT|File::WRONLY)
      aFile.puts(pid)
      aFile.flush
      aFile.close
   end
   ## -----------------------------------------------------------

   ## It checks if a process name is running with the given PID.
   ## * It returns true if the given process is running.
   ## * Otherwise It returns false.
   def checkProcess(pid)
      if @isRuby == true then
         #ruby = `which ruby`.chop
         ruby = "ruby"
         command = %Q{ps -f -p #{pid} | grep #{ruby} | grep #{@processName} }
      else
         command = %Q{ps -f -p #{pid} | grep #{@processName} }
      end
      retVal = `#{command}`
      if @isDebugMode == true then
         puts "\n#{command}\n"
         puts "return: #{retVal}\n"
      end
      if retVal != "" then
         return true
      else
         return false
      end
   end
   ## -----------------------------------------------------------

end ### class

end ### module
