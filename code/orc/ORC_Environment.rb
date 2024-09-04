#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #ORC_Environment class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Orchestrator (generic orchestrator)
### 
### Git: $Id: ORC_Environment.rb $Date$
###
### module ORC
###
#########################################################################

require 'dotenv'
require 'cuc/DirUtils'
require_relative 'ReadOrchestratorConfig'

module ORC
   
   include CUC::DirUtils
   
   VERSION   = "0.0.18.0"
   
   ## ----------------------------------------------------------------
   
   CHANGE_RECORD = { \
      "0.0.18"  =>   "New configuration rule for NAOS PLA_PGU", \
      "0.0.17"  =>   "Handling of previously archived inputs / reprocessing using orcQueueInput -d <file>", \
      "0.0.16"  =>   "New unit test for BOA generic configuration", \
      "0.0.15"  =>   "New configuration item ArchiveHandler used to select the minARC plug-in\n\
          orcValidateConfig option to print the configuration directory\n\
          Unit test created for NAOS",\
      "0.0.14"  =>   "orcValidateConfig checks the integrity of all rules beyond the xsd schema", \
      "0.0.13"  =>   "Robustification to handle miss-configuration of processing rules:\n\
          https://jira.elecnor-deimos.com/browse/S2MPASUP-449",\
      "0.0.12"  =>   "Logs updated to report new message ORC_230", \
      "0.0.11"  =>   "fixed https://jira.elecnor-deimos.com/browse/S2MPASUP-409 / S2 hardcoded filtering", \
      "0.0.10"  =>   "orchestratorConfigFile.xml Inventory item added for database configuration\n\
          Support to remote inventory / db different than localhost\n\
          Inventory config now includes Database_Host & Database_Port items:\n\
          https://jira.elecnor-deimos.com/browse/S2MPASUP-384\n\
          Datamodel & Index updated to deal with previously queued items:\n\
          https://jira.elecnor-deimos.com/browse/S2MPASUP-402\n\
          log messages rationalisation and clean-up",\
      "0.0.9"  =>    "unit tests execution environment can be parametrised with env file\n\
         orcQueueUpdate removes from the queue a previously failed product\n\
         orcValidateConfig has been created:\n\
         improved resilience and race condition problem fixed according to tickets below:\n\
         https://jira.elecnor-deimos.com/browse/S2MPASUP-302\n\
         https://jira.elecnor-deimos.com/browse/S2MPASUP-288\n\
         https://jira.elecnor-deimos.com/browse/S2MPASUP-294", \
      "0.0.8"  =>    "fixed https://jira.elecnor-deimos.com/browse/S2MPASUP-292 / migration to ActiveRecord 6", \
      "0.0.7"  =>    "fixed https://jira.elecnor-deimos.com/browse/S2MPASUP-277 regarding race conditions when triggering jobs", \
      "0.0.6"  =>    "ingestion parallelised (new configuration ParallelIngestions)", \
      "0.0.5"  =>    "orcQueueUpdate fixed to fit with the new data-model", \
      "0.0.4"  =>    "orcQueueInput bulk mode support of pending triggers\n\
         OrchestratorScheduler now uses such bulk mode", \
      "0.0.3"  =>    "Check of tool dependencies done in the unit tests\n\
         Dotenv gem has been added to the Gemfile", \
      "0.0.2"  =>    "Unused dependencies with DEC/ctc sources removed", \
      "0.0.1"  =>    "First cleaned-up version of the orchestrator" \
   }

   ## ----------------------------------------------------------------
   
   @@arrEnv = [ \
               "ORC_TMP", \
               "ORC_DB_ADAPTER", \
               "ORC_DATABASE_HOST", \
               "ORC_DATABASE_PORT", \
               "ORC_DATABASE_NAME", \
               "ORC_DATABASE_USER", \
               "ORC_DATABASE_PASSWORD" \
              ]
   
   ## ----------------------------------------------------------------
   
   @@arrTools = [ \
                 "sqlite3", \
                 "orcManageDB", \
                 "orcQueueInput", \
                 "orcIngester", \
                 "orcScheduler", \
                 "orcBolg" \
                ]
   
   ## ----------------------------------------------------------------
   
   ## -----------------------------------------------------------------

   def load_config
   
      # --------------------------------
      if !ENV['ORC_CONFIG'] then
         ENV['ORC_CONFIG'] = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
      end
      # --------------------------------

      orcConfig   = ORC::ReadOrchestratorConfig.instance
      inventory   = orcConfig.getInventory
         
      if !ENV['ORC_DB_ADAPTER'] then
         ENV['ORC_DB_ADAPTER'] = inventory[:db_adapter]
      end

      if !ENV['ORC_DATABASE_HOST'] then
         ENV['ORC_DATABASE_HOST'] = inventory[:db_host]
      end

      if !ENV['ORC_DATABASE_PORT'] then
         ENV['ORC_DATABASE_PORT'] = inventory[:db_port]
      end
   
      if !ENV['ORC_DATABASE_NAME'] then
         ENV['ORC_DATABASE_NAME'] = inventory[:db_name]
      end
   
      if !ENV['ORC_DATABASE_USER'] then
         ENV['ORC_DATABASE_USER'] = inventory[:db_username]
      end   

      if !ENV['ORC_DATABASE_PASSWORD'] then
         ENV['ORC_DATABASE_PASSWORD'] = inventory[:db_password]
      end
      
      if !ENV['ORC_TMP'] then
         ENV['ORC_TMP'] = orcConfig.getTempDir
      end   
      
   end

   ## -----------------------------------------------------------------

   
   def load_environment_test
      env_file = File.join(File.dirname(File.expand_path(__FILE__)), '../../install', 'orc_test.env')
      Dotenv.overload(env_file)
      ENV['ORC_CONFIG']                   = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
   end
   
   ## -----------------------------------------------------------------
   
#   def load_config_development
#      ENV['ORC_DB_ADAPTER']               = "sqlite3"
#      ENV['ORC_TMP']                      = "/tmp"
#      ENV['ORC_DATABASE_NAME']            = "#{ENV['HOME']}/Sandbox/inventory/orc_inventory"
#      ENV['ORC_DATABASE_USER']            = "root"
#      ENV['ORC_DATABASE_PASSWORD']        = "1mysql"
#      ENV['ORC_CONFIG']                   = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
#   end
   
   ## -----------------------------------------------------------------
   
   def unset_config
      @@arrEnv.each{|vble|
         ENV.delete(vble)
      }
   end
   ## -----------------------------------------------------------------
   
   def load_environment(filename)
      env_file = File.join(File.dirname(File.expand_path(__FILE__)), '../../config', filename)
      
      if File.exist?(env_file) == false then
         puts "environment file #{env_file} not found"
         return false
      end
      
      Dotenv.overload(env_file)
      ENV['ORC_CONFIG'] = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
   end 
   ## ----------------------------------------------------------------
   
   def print_environment
      puts "HOME                          => #{ENV['HOME']}"
      puts "ORC_TMP                       => #{ENV['ORC_TMP']}"
      puts "ORC_DB_ADAPTER                => #{ENV['ORC_DB_ADAPTER']}"
      puts "ORC_DATABASE_HOST             => #{ENV['ORC_DATABASE_HOST']}"
      puts "ORC_DATABASE_PORT             => #{ENV['ORC_DATABASE_PORT']}"
      puts "ORC_DATABASE_NAME             => #{ENV['ORC_DATABASE_NAME']}"
      puts "ORC_DATABASE_USER             => #{ENV['ORC_DATABASE_USER']}"
      puts "ORC_DATABASE_PASSWORD         => #{ENV['ORC_DATABASE_PASSWORD']}"
      puts "ORC_CONFIG                    => #{ENV['ORC_CONFIG']}"
   end
   ## ----------------------------------------------------------------
  
   def log_environment(logger)
      logger.info("ORC_TMP           => #{ENV['ORC_TMP']}")
      logger.info("ORC_CONFIG        => #{ENV['ORC_CONFIG']}")
      logger.info("ORC_DB_ADAPTER    => #{ENV['ORC_DB_ADAPTER']}")
      logger.info("ORC_DATABASE_HOST => #{ENV['ORC_DATABASE_HOST']}")
      logger.info("ORC_DATABASE_PORT => #{ENV['ORC_DATABASE_PORT']}")
      logger.info("ORC_DATABASE_NAME => #{ENV['ORC_DATABASE_NAME']}")
      logger.info("ORC_DATABASE_USER => #{ENV['ORC_DATABASE_USER']}")
      logger.info("ORC_DATABASE_PASSWORD => #{ENV['ORC_DATABASE_PASSWORD']}")
   end
   ## ----------------------------------------------------------------

   def check_environment
      retVal = checkEnvironmentEssential
      if retVal == true then
         check_environment_dirs
         return checkToolDependencies
      else
         return false
      end
   end
   ## ----------------------------------------------------------------

   def check_environment_dirs
      
      checkDirectory(ENV['ORC_TMP'])
      checkDirectory("#{ENV['HOME']}/Sandbox/inventory/")
      
      orcConf = ORC::ReadOrchestratorConfig.instance
      
      checkDirectory(orcConf.getPollingDir)
      checkDirectory(orcConf.getProcWorkingDir)
      checkDirectory(orcConf.getSuccessDir)
      checkDirectory(orcConf.getFailureDir)
      checkDirectory(orcConf.getBreakPointDir)
      checkDirectory(orcConf.getTmpDir)    
   end
   
   ## ----------------------------------------------------------------

   def createEnvironmentDirs
      checkDirectory(ENV['ORC_TMP'])
      checkDirectory("#{ENV['HOME']}/Sandbox/inventory/")
   end

   ## ----------------------------------------------------------------

   def checkEnvironmentEssential
      
      load_config
      
      bCheck = true
            
      @@arrEnv.each{|vble|
         if !ENV.include?(vble) then
            bCheck = false
            puts "orchestrator environment variable #{vble} is not defined !\n"
            puts
         end
      }
      
      # --------------------------------
      # ORC_CONFIG can be defined by the customer to override 
      # the configuration shipped with the gem
      if !ENV['ORC_CONFIG'] then
         ENV['ORC_CONFIG'] = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
      end
      # --------------------------------
   
      orcConf = ORC::ReadOrchestratorConfig.instance
      orcConf.update

      resMan = orcConf.getResourceManager

      cmd1           = "which #{resMan}"
      isToolPresent  = `#{cmd1}`
      
      if isToolPresent[0,1] != '/' and ($? != 0) then
         puts "#{resMan} not present in PATH !  :-(\n"
         puts "check orchestratorConfigFile.xml => ResourceManager configuration"
         bCheck = false
      end

      triggers = orcConf.getAllTriggerTypeInputs
      
      triggers.each{|trigger|
         executable = orcConf.getExecutable(trigger).split(" ")[0]
         cmd = "which #{executable}"
         isToolPresent = `#{cmd}`
         if isToolPresent[0,1] != '/' then
            puts "#{executable} not in path / rule #{trigger}"
            bCheck = false
         end
      }
                  
      if bCheck == false then
         puts "ORC environment / configuration not complete"
         puts
         return false
      end
      return true
   end
   ## ----------------------------------------------------------------

   def printEnvironmentError
      puts "Execution environment not suited for ORC"
   end
   ## ----------------------------------------------------------------

   ## -----------------------------------------------------------------

   ## extract ORC configuration from installation directory 
   def copy_installed_config(destination, nodename = "")
      checkDirectory(destination)
      ## -----------------------------
      ## ORC Config files
   
      arrConfigFiles = [\
         "orchestratorConfigFile.xml",\
         "orchestrator_log_config.xml"]
      ## -----------------------------

      path = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
      
      arrConfigFiles.each{|config|
         if File.exist?("#{path}/#{config}") == true then
            FileUtils.cp("#{path}/#{config}", "#{destination}/#{nodename}##{config}")
            if File.exist?("#{destination}/#{config}") == false then
               FileUtils.ln_s("#{destination}/#{nodename}##{config}","#{destination}/#{config}")
            end
         else
            puts "Missing config file #{config} in gem installation"
         end
      }
   end
   ## -----------------------------------------------------------------

   def getConfigDir
      if !ENV['ORC_CONFIG'] then
         return File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
      else
         return ENV['ORC_CONFIG']
      end
   end

   ## ----------------------------------------------------------------
   
   def checkToolDependencies
      
      bCheck = true
      bCheckOK = true
      
      @@arrTools.each{|tool|
         isToolPresent = `which #{tool}`
               
         if isToolPresent[0,1] != '/' then
            puts "\n\nORC_Environment::checkToolDependencies\n"
            puts "Fatal Error: #{tool} not present in PATH !!   :-(\n\n\n"
            bCheckOK = false
         end

      }

      if bCheckOK == false then
         puts "orchestrator environment configuration is not complete"
         puts
         return false
      end
      return true      
   end
   
   ## ----------------------------------------------------------------
      
   
end # module

## =============================================================================

## Wrapper to make use within unit tests since it is not possible inherit mixins

class ORC_Environment
   
   include ORC

   def wrapper_load_config
      load_config
   end

   def wrapper_load_config_development
      load_config_development
   end

   def wrapper_load_environment_test
      load_environment_test
   end
   
   def wrapper_load_environment(envFile)
      return load_environment(envFile)
   end

   def wrapper_print_environment
      print_environment
   end

   def wrapper_check_environment
      return check_environment
   end

   def wrapper_unset_config
      unset_config
   end
   
   def wrapper_setRemoteModeOnly
      setRemoteModeOnly
   end
   
   def wrapper_setLocalModeOnly
      setLocalModeOnly
   end
   
   def wrapper_createEnvironmentDirs
      check_environment_dirs
   end
   
end

## =============================================================================
