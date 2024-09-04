#!/usr/bin/env ruby

#########################################################################
#
# = Ruby source for #ProcessHandler class
#
# = Written by DEIMOS Space S.L. (bolf)
#
# = Data Exchange Component -> Common Utils Component
# 
# CVS:
#   $Id: Listener.rb,v 1.1 2006/09/11 16:46:55 decdev Exp $
#
#########################################################################

   # This class implements a generic listener (daemon).
   # It is checked that it is not running a listener with a given name.

require "cuc/DirUtils"
require "cuc/CheckerProcessUniqueness"


NRTP_STATUS = ["NRTP_STATUS_SUCCESS", "NRTP_STATUS_FAILED", "NRTP_STATUS_ACK"]

NRTP_STATUS_SUCCESS     = 0
NRTP_STATUS_FAILED      = 1
NRTP_STATUS_ACK         = 2

class ProcessHandler

   include CUC::DirUtils
   #-------------------------------------------------------------
   
   # Class constructor.
   # IN Parameters:
   # * string: the name of the listener process.
   # * string: param of the listener process.
   # First of all check if it is already running.
   # Only one process Listener is allowed.
   def initialize(processName = "", cmd = "", pidObserver = 0)
      checkModuleIntegrity
      @pidObserver = pidObserver
      @processName = processName
      @cmd         = cmd
               
      @procLocker = CUC::CheckerProcessUniqueness.new(processName, "", false)     

      if @procLocker.isRunning == true then
         @pidHandler = @procLocker.getRunningPID
         if @pidHandler == false then
            @pidHandler = 0
         else
            @pidHandler = @pidHandler.to_i
         end
      else
         @pidHandler = 0
      end
     
      @isDebugMode = false
   end   
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "NRTProcessHandler debug mode is on"
      @procLocker.setDebugMode
   end
   #-------------------------------------------------------------   

   def stop
      puts "ProcessHandler::stop"
      if @procLocker.isRunning == false then
         return false
      end
      puts "Sending Signal SIGUSR1 to #{@pidHandler}"
      Process.kill("USR1", @pidHandler)
   end
   #-------------------------------------------------------------

   def resume
      puts "ProcessHandler::resume"
      if @procLocker.isRunning == false then
         return false
      end
      puts "Sending Signal SIGCONT to #{@pidHandler}"
      Process.kill("CONT", @pidHandler)
   end
   #-------------------------------------------------------------

   def quit
      puts "ProcessHandler::quit"
      if @procLocker.isRunning == false then
         return false
      end
      puts "Sending Signal SIGKILL to #{@pidHandler}"
      Process.kill("KILL", @pidHandler)
   end
   
   
   #-------------------------------------------------------------



   def abort
      puts "ProcessHandler::abort"
      if @procLocker.isRunning == false then
         return false
      end
      puts "Sending Signal SIGINT to #{@pidHandler}"
      Process.kill("INT", @pidHandler)
   end
   
   
   #-------------------------------------------------------------

   def status
      return @procLocker.isRunning
   end
   #-------------------------------------------------------------
   
   def pause
      puts "ProcessHandler::abort"
      if @procLocker.isRunning == false then
         return false
      end
      puts "Sending Signal SIGTSTP to #{@pidHandler}"
      Process.kill("SIGTSTP", @pidHandler)
   end
   #-------------------------------------------------------------
   
   def run
   
      if @procLocker.isRunning == true then
         return false
      end
      
      # Parent exists, child continue
      exit!(0) if fork
   
      # Become session leader without a controlling TTY
      Process.setsid
   
      exit!(0) if fork
         
      @procLocker.setRunning
         
      Dir.chdir("/")   
      File.umask(0000)
   
      if @isDebugMode == true then
         puts "#{File.basename($0)} set as daemon with pid #{Process.pid}\n\n"
      end
   
  #   Redirect standard streams    
      STDIN.reopen("/dev/null")
  
      if @isDebugMode == false then
         STDOUT.reopen("/dev/null")
         STDERR.reopen STDOUT
      end   
   
      # Pass as an argument, current process (daemon) PID
      myPID = Process.pid 
      @cmd  = "#{@cmd} -p #{myPID}"
      
      # Register Signals
      registerSignals
      
      @@childPID     = 0
      @childStatus   = 99
      
      pid = fork {
      
         @@childPID = Process.pid
         @mpiLocker = CUC::CheckerProcessUniqueness.new("mpirun", "", false)
         @mpiLocker.setExternalProcessRunning(@@childPID)
         puts @cmd
         exec(@cmd)
         # system(@cmd)
      }

      # Parent waits for child
      if pid != nil then
         Process.detach(pid)
         Process.wait
         processSIGCHILD
      end

      @procLocker.release
      return true
   
   end
   #-------------------------------------------------------------
   
private

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true
   
      if !ENV['NRTP_HMI_TMP'] then
        puts "\nNRTP_HMI_TMP environment variable not defined !  :-(\n\n"
        bCheckOK = false
        bDefined = false
      end
      
      if bCheckOK == false then
        puts "NRTProcessHandler::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end
      @hmiStatusDirectory = ENV['NRTP_HMI_TMP']
      checkDirectory(@hmiStatusDirectory)
   end
   #-------------------------------------------------------------
   
   # Register Signals
   def registerSignals
   
      trap("SIGHUP") {  puts "\nPolling requested for #{@mnemonic} I/F ...\n" }
   
      trap("USR1")   {  
                        processSIGUSR1 
                     }
      
      trap("USR2")   {  
                        processSIGUSR2
                     }
      
      trap("SIGTSTP"){  
                        puts "\nSignal SIGTSTP received ...\n"
                        processSIGTSTP
                     }
      
      trap("CONT")   {  
                        puts "\nSignal SIGCONT received ...\n"
                        processSIGCONT
                     }
    
#       trap("CLD")    {  
#                         puts "\nSignal SIGCHILD received :-)...\n"
#                         processSIGCHILD
#                      }
   
      trap("INT")    {  
                        puts "\nSignal SIGINT (CTRL+C) received ...\n"
                        processSIGINT 
                     }
      
   end
   #-------------------------------------------------------------

   #
   def processSIGUSR1
      @mpiLocker = CUC::CheckerProcessUniqueness.new("mpirun", "", false)
      ret = @mpiLocker.getRunningPID
      if ret != false then
         Process.kill("USR1", ret.to_i)
      else
         puts "mpirun is not present"
      end
      createStatusFile(NRTP_STATUS_ACK)
      sendSignal2Observer
   end
   
   #-------------------------------------------------------------
   
   #   
   def processSIGUSR2
      createStatusFile(NRTP_STATUS_ACK)
      sendSignal2Observer
   end
      
   #-------------------------------------------------------------

   #   
   def processSIGCHILD
      if $?.exitstatus == 0 then
         createStatusFile(NRTP_STATUS_SUCCESS)
      else
         createStatusFile(NRTP_STATUS_FAILED)
      end
      sendSignal2Observer
   end
      
   #-------------------------------------------------------------

   #   
   def processSIGCONT
      @mpiLocker = CUC::CheckerProcessUniqueness.new("mpirun", "", false)
      ret = @mpiLocker.getRunningPID
      if ret != false then
         Process.kill("CONT", ret.to_i)
      else
         puts "mpirun is not present"
      end
   end
   #-------------------------------------------------------------

   #   
   def processSIGTSTP
      @mpiLocker = CUC::CheckerProcessUniqueness.new("mpirun", "", false)
      ret = @mpiLocker.getRunningPID
      if ret != false then
         Process.kill("SIGTSTP", ret.to_i)
      else
         puts "Could not send SIGTSTP to mpirun"
      end
   end
   #-------------------------------------------------------------
      
   # CTRL + C to Abort Execution  
   def processSIGINT
      @mpiLocker = CUC::CheckerProcessUniqueness.new("mpirun", "", false)
      ret = @mpiLocker.getRunningPID
      if ret != false then
         Process.kill("INT", ret.to_i)
      else
         puts "Could not send SIGINT to mpirun"
      end
      createStatusFile(NRTP_STATUS_FAILED)
   end
   #-------------------------------------------------------------
   
   # Create Status notification file
   def createStatusFile(status)
      strStatus = ""
      case status         
         when NRTP_STATUS_SUCCESS then strStatus = "NRTP_STATUS_SUCCESS"
         when NRTP_STATUS_FAILED  then strStatus = "NRTP_STATUS_FAILED"
         when NRTP_STATUS_ACK     then strStatus = "NRTP_STATUS_ACK"
      else
         puts
         puts "#{status} ststus not supported ! :-("
         puts "NRTProcessHandler::createStatusFile"
         puts   
      end
   
      pwd = Dir.pwd
      
      Dir.chdir(@hmiStatusDirectory)
      
      # Override all previous msg Files
      NRTP_STATUS.each{|statusFile|
         begin
            File.delete(statusFile)
         rescue Exception => e
         end
      }
      
      cmd = "touch #{strStatus}"
      system(cmd)
      
      Dir.chdir(pwd)
      
   end
   #-------------------------------------------------------------
   
   def sendSignal2Observer
      
      #-------------------------------------------------
      
      # Inform Process Observer
      if @pidObserver != 0 then
         begin
            Process.kill("SIGUSR2", @pidObserver)
         rescue Exception => e
            puts
            puts "Could not send signal to process Observer :-|"
            #puts e.to_s
            #puts
         end
      end
      #-------------------------------------------------      
   end
   #-------------------------------------------------------------
   
end # class
