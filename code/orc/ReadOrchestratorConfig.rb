#!/usr/bin/env ruby

#########################################################################
##
## === Ruby source for #ReadOrchestratorConfig class          
##
## === Written by DEIMOS Space S.L.
##
## ===  ORC Component
## 
## $Id: ReadOrchestratorConfig.rb,v 1.11 2009/03/24 16:35:22 decdev Exp $
##
## This class processes $ORC_CONFIG/orchestratorConfigFile.xml
## which contain all the configuration related to the ORCHESTRATOR
##
#########################################################################

require 'singleton'
require 'rexml/document'

module ORC

class ReadOrchestratorConfig

   include Singleton
   include REXML

   ## -----------------------------------------------------------

   ## Class constructor
   def initialize
      @isDebugMode        = true
      @inventory          = nil
      checkModuleIntegrity
      defineStructs
      loadData
   end
   ## -----------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "ReadOrchestratorConfig debug mode is on"
   end
   ## -----------------------------------------------------------

   ## Reload data from files
   ## This is the method called when the config files are modified
   def update
#      if @isDebugMode then
#         print("\nReceived Notification that the config files have changed\n")
#      end
      loadData
   end
   ## -----------------------------------------------------------


   #----------------Data Provider Methods------------------------
   #-------------------------------------------------------------

   # Returns an array with the structs of the DataProviders
   def getAllDataProviders
      return @@arrOrchDataProvider
   end
   #-------------------------------------------------------------

   # Returns an array with all the Fyle Types
   def getAllFileTypes
     arrFileType = Array.new
     @@arrOrchDataProvider.each { |x| arrFileType << x[:fileType] }
     return arrFileType
   end
   #-------------------------------------------------------------
   
   # Returns an array with all the Data Types
   def getAllDataTypes
      arrDataType = Array.new
      @@arrOrchDataProvider.each { |x| arrDataType << x[:dataType] }    
      return arrDataType
   end
   ## -----------------------------------------------------------

   ## Gets the dataType providing a fileType
   def getDataType(fileType_)
      @@arrOrchDataProvider.each { |x|
         # puts "fnmatch #{x[:fileType]} => #{fileType_}"
         if x[:fileType] == fileType_ or \
               File.fnmatch(x[:fileType], fileType_) == true then
            return x[:dataType]
         end
      }
      return nil
   end
   ## -----------------------------------------------------------
   
   # Gets the fileType providing a dataType
   def getFileType(dataType_)
      @@arrOrchDataProvider.each { |x|
         if x[:dataType] == dataType_ then
            return x[:fileType]
         end
      }
      return nil
   end
   #-------------------------------------------------------------

   # Checks if a fileType is trigger, if its not a valid value returns nil.
   def isFileTypeTrigger?(fileType_)
      @@arrOrchDataProvider.each { |x|
      
#         puts fileType_
#         puts x[:fileType]
#         puts File.fnmatch(x[:fileType], fileType_)
#         puts x[:isTrigger]
      
         if x[:fileType] == fileType_ or \
               File.fnmatch(x[:fileType], fileType_) == true then
            if x[:isTrigger] == "yes" then
               return true
            end
            if x[:isTrigger] == "no" then
               return false
            end
            return nil
         end
      }
      return false
   end
   #-------------------------------------------------------------

   # Checks if a dataType is trigger, if its not a valid value returns nil.
   def isDataTypeTrigger? (dataType_)
      @@arrOrchDataProvider.each { |x|
         if x[:dataType] == dataType_ then
            if x[:isTrigger] == "yes" then
               return true
            end
            if x[:isTrigger] == "no" then
               return false
            end
            return nil
         end
      }
      return false
   end
   ## -------------------------------------------------------------

   ## Checks if the fileType provided exists
   def isValidFileType?(fileType_)
      @@arrOrchDataProvider.each { |x|
      
#         puts "checking #{x[:fileType]} => #{fileType_}"
#         puts File.fnmatch(x[:fileType], fileType_)
      
      
         if x[:fileType] == fileType_ or \
               File.fnmatch(x[:fileType], fileType_) == true then
            return true
         end
         
         
      }
      return false
   end
   ## -----------------------------------------------------------

   # Checks if the dataType provided exists
   def isValidDataType?(dataType_)
      @@arrOrchDataProvider.each { |x|
         if x[:dataType] == dataType_ then
            return true
         end
      }
      return false
   end
   #-------------------------------------------------------------


   #--------------------Priority Rules---------------------------
   #-------------------------------------------------------------

   # Returns all the priority rules
   def getPriorityRules
      return @@arrOrchPriorityRule
   end
   #-------------------------------------------------------------

   # Returns an array with all the dataTypes defined in the priority rules list
   def getAllDataTypePri
     @arrDataTypePri = Array.new
     @@arrOrchPriorityRule.each { |x|
       @arrDataTypePri << x[:dataType] }
     return @arrDataTypePri
   end
   #-------------------------------------------------------------   

   #-------------------------------------------------------------
   # Returns the rank of a given datatype if its on the priority list
   # else it returns 0
   def getRank(dataType)
      @@arrOrchPriorityRule.each { |x|
         if x[:dataType] == dataType then
            return x[:rank]
         end
         }
      return 0
   end
   #-------------------------------------------------------------

   # Returns the sorting of a given datatype if its on the priority list
   # else it returns nil
   def getSorting(dataType)
      @@arrOrchPriorityRule.each { |x|
         if x[:dataType] == dataType then
            return x[:sort]
         end
         }
      return nil
   end
   #-------------------------------------------------------------


   #----------------Process Rules Methods------------------------
   #-------------------------------------------------------------

   def getAllProcessRules    
      @@arrOrchProcessRule.each { |x|
         puts "#{x[:output]} #{x[:triggerInput]} #{x[:coverage]}"
         puts "executable: #{x[:executable]}"
         puts "List of inputs:"
         x[:listOfInputs].each { |y|
              puts "#{y[:dataType]} #{y[:coverage]} #{y[:mandatory]}"
            }
         puts
         }
      return @@arrOrchProcessRule
   end
   #-------------------------------------------------------------

   # Returns an array with all the trigger_types (data_types)
   # of the process rules
   def getAllTriggerTypeInputs
     @arrAllTriggerType = Array.new
     @@arrOrchProcessRule.each { |x| @arrAllTriggerType << x[:triggerInput]}
     return @arrAllTriggerType
   end
   #-------------------------------------------------------------

   # Returns an array with all the outputs of the process rules
   def getAllOutputs
     @arrAllOutputs = Array.new
     @@arrOrchProcessRule.each { |x| @arrAllOutputs << x[:output]}
     return @arrAllOutputs
   end
   ## -----------------------------------------------------------

   ## It returns the executable command for the triggerType
   ## else it returns nil
   def getExecutable(triggerType_)
      @@arrOrchProcessRule.each { |x|
         if x[:triggerInput] == triggerType_ then
            return x[:executable]
         end
      }
      return nil
   end
   ## -----------------------------------------------------------

   # Wrap for getListOfInputs
   def getListOfInputsByTriggerDataType(dataType_)
      return getListOfInputs(dataType_)
   end
   #-------------------------------------------------------------

   # Returns the list of inputs of a given triggerType (dataType)
   # else returns nil
   def getListOfInputs(triggerType_)
      @@arrOrchProcessRule.each { |x|
         if x[:triggerInput] == triggerType_ then
            return x[:listOfInputs]
         end
      }
      return nil
   end
   #-------------------------------------------------------------

   # It retrieves the result data-type of a given processing rule
   # receiving as argument the trigger data-type
   def getResultDataType(dataType_)
      @@arrOrchProcessRule.each { |x|
         if x[:triggerInput] == dataType_ then
            return x[:output]
         end
      }
      return nil
   end
   #-------------------------------------------------------------

   # It retrieves the coverage mode of a given processing rule
   # receiving as argument the trigger data-type
   def getTriggerCoverageByInputDataType(dataType_)
      @@arrOrchProcessRule.each { |x|
         if x[:triggerInput] == dataType_ then
            return x[:coverage]
         end
      }
      return nil
   end
   #-------------------------------------------------------------


   #----------------Processing Parameters Methods----------------
   #-------------------------------------------------------------
   
   def getAllProcParameters
      return @@listOfProcParameters
   end
   #-------------------------------------------------------------

   def getProcParameter(name)
      @@listOfProcParameters.each{|procParam|
         if procParam[:name] == name then
            return procParam
         end
      }
      return nil
   end
   #-------------------------------------------------------------



   # ----------------Miscelanea Methods---------------------------
   def getArchiveHandler
      return @@miscelanea[:archiveHandler]
   end
   ## ------------------------------------------------------------
   
   def getAllMiscelanea
      return @@miscelanea
   end
   ## -----------------------------------------------------------

   def getPollingDir
      return @@miscelanea[:pollingDir]
   end
   ## -----------------------------------------------------------

   def getSchedulingFreq
      return @@miscelanea[:schedulingFreq]
   end
   # -------------------------------------------------------------

   def getParallelIngest
      return @@miscelanea[:parallelIngest]
   end
   # -------------------------------------------------------------

   def getResourceManager
      return @@miscelanea[:resourceManager]
   end
   # -------------------------------------------------------------

   def getPollingFreq
      return @@miscelanea[:pollingFreq]
   end
   # -------------------------------------------------------------

   def getProcWorkingDir
      return @@miscelanea[:procWorkingDir]
   end
   # -------------------------------------------------------------

   def getSuccessDir
      return @@miscelanea[:successDir]
   end
   # -------------------------------------------------------------

   def getFailureDir
      return @@miscelanea[:failureDir]
   end
   # -------------------------------------------------------------

   def getBreakPointDir
      return @@miscelanea[:breakPointDir]
   end
   # -------------------------------------------------------------

   def getTempDir
      return @@miscelanea[:tmpDir]
   end
   # -------------------------------------------------------------

   def getTmpDir
      return @@miscelanea[:tmpDir]
   end
   # -------------------------------------------------------------

   def getInventory
      return @inventory
   end
   # ------------------------------------------------------------


   # -------------------------------------------------------------
   # ---------------Private section-------------------------------
   # -------------------------------------------------------------

private

   @@arrOrchDataProvider    = nil
   @@arrOrchPriorityRule    = nil
   @@arrOrchProcessRule     = nil
   @@miscelanea             = nil
   @@configDirectory        = ""
   ## -----------------------------------------------------------

   ## This method defines all the structs used in this class
   def defineStructs
      Struct.new("OrchDataProvider", :isTrigger, :dataType, :fileType)
      Struct.new("OrchPriorityRule", :rank, :dataType, :fileType, :sort)
      Struct.new("OrchProcessRule", :output, :triggerInput, :coverage, :executable, :listOfInputs)  #output is dataType on the orchestratorConfig.xml (processing rules)
      Struct.new("OrchListOfInputs", :dataType, :coverage, :mandatory, :excludeDataType)
      Struct.new("OrchMiscelanea", :archiveHandler, :pollingDir, :pollingFreq, :parallelIngest, :schedulingFreq, :resourceManager, :procWorkingDir, :successDir, :failureDir, :breakPointDir, :tmpDir)
      Struct.new("OrchProcParameter", :name, :value, :unit)

      if Struct::const_defined? "Inventory" then
         Struct.const_get "Inventory"
      else
         Struct.new("Inventory", :db_adapter, \
                                 :db_host, \
                                 :db_port, \
                                 :db_name, \
                                 :db_username, \
                                 :db_password)
      end
            
   end
   ## -----------------------------------------------------------

   def fillProcParameter(name, value, unit)
      return Struct::OrchProcParameter.new(name, value, unit)
   end
   # -------------------------------------------------------------

   def fillDataProvider(isTrigger, dataType, fileType)
      return Struct::OrchDataProvider.new(isTrigger, dataType, fileType)
   end
   # -------------------------------------------------------------

   def fillPriorityRule(rank, dataType, fileType, sort)
      if sort.upcase != "ASC" and sort.upcase != "DESC" and sort.upcase != "" then
         puts "Fatal Error in ReadOrchestratorConfig::fillPriorityRule  ! :-("
         puts sort
         puts
         exit(99)
      end
      return Struct::OrchPriorityRule.new(rank, dataType, fileType, sort.upcase)
   end
   #-------------------------------------------------------------

   def fillProcessRule(output, triggerInput, coverage, executable, listOfInputs)
      return Struct::OrchProcessRule.new(output, triggerInput, coverage, executable, listOfInputs)
   end
   #-------------------------------------------------------------

   def fillListOfInputs(dataType, coverage, mandatory, excludeDataType = nil)
      return Struct::OrchListOfInputs.new(dataType, coverage, mandatory, excludeDataType)
   end
   #-------------------------------------------------------------

   def fillMiscelanea(archiveHandler, pollingDir, pollingFreq, parallelIngest, schedulingFreq, resourceManager, procWorkingDir, successDir, failureDir, breakPointDir, tmpDir)
      return Struct::OrchMiscelanea.new(archiveHandler, pollingDir, pollingFreq, parallelIngest, schedulingFreq, resourceManager, procWorkingDir, successDir, failureDir, breakPointDir, tmpDir)
   end
   ## -----------------------------------------------------------

   ## Load the file into the internal struct File defined in the
   ## class Constructor. See initialize.
   def loadData
      orchFilename = %Q{#{@@configDirectory}/orchestratorConfigFile.xml}
      fileOrch     = File.new(orchFilename)
      xmlOrch      = REXML::Document.new(fileOrch)

#       if @isDebugMode == true then
#          puts "\nParsing #{orchFilename}"
#       end

      parseDataProviders(xmlOrch)
      parsePriorityRules(xmlOrch)
      parseProcessRules(xmlOrch)
      parseProcParameters(xmlOrch)
      parseMiscelanea(xmlOrch)
      parseInventory(xmlOrch)
   end
   ## -----------------------------------------------------------


   # Process File, Data providers section
   # - xmlFile (IN): XML file
   def parseDataProviders(xmlFile)

      isTrigger      = false
      file           = ""
      data           = ""
      arr            = Array.new

      # For each Data provider entry

      XPath.each(xmlFile,"OrchestratorConfiguration/List_of_DataProviders/DataProvider"){
         |dp|

         # Gets the data provider atribute matching "isTriggerType"
        # str= dp.attributes["isTriggerType"]

         isTrigger= dp.attributes["isTriggerType"]
      
         # Get the 2 children elements of each dataProvider (data type and file type)
         data = dp.elements[1].text
         file = dp.elements[2].text

         arr << fillDataProvider(isTrigger, data, file)

      }
      @@arrOrchDataProvider = arr

   end
   #---------------------------------------------------------------


   # Process File, Priority Rules section
   # - xmlFile (IN): XML file
   def parsePriorityRules(xmlFile)

      rank        = 0
      fileType    = ""
      dataType    = ""
      sort        = ""
      arr         = Array.new

      XPath.each(xmlFile,"OrchestratorConfiguration/List_of_PriorityRules/PriorityRule"){
         |aRule|

         # Mandatory attributes for each Priority Rule

         rank     = aRule.attributes["rank"].to_i
         dataType = aRule.attributes["type"]
         fileType = getFileType(dataType)

         # optional attributes
         aRule.attributes.each_attribute{|attr|
            if attr.name == "sort" then
               sort = aRule.attributes["sort"]
               break
            end
         }

         arr << fillPriorityRule(rank, dataType, fileType, sort)

      }
      @@arrOrchPriorityRule = arr
   end
   #---------------------------------------------------------------


   # Process File, Process rules module
   # - xmlFile (IN): XML file
   def parseProcessRules(xmlFile)

      isTrigger      = false
      file           = ""
      data           = ""
      executable     = ""
      arr            = Array.new
      @ListOfInputs  = Array.new

      XPath.each(xmlFile, "OrchestratorConfiguration/List_of_ProcessingRules/ProcessingRule"){
         |pr|

         # Get the data provider atributes
         output        = pr.attributes["dataType"]
         triggerInput  = pr.attributes["triggerType"]
         coverage      = pr.attributes["coverage"]


         # Get the first child on the xml tree (executable)
         executable    = pr.elements[1].text

         # Get the List of inputs for each process rule
         XPath.each(pr, "List_of_Inputs/Input"){
            |loi|

            dataType    = loi.attributes["dataType"]
            coverage_   = loi.attributes["coverage"]
            mandatory   = loi.attributes["mandatory"].to_s.upcase

            if mandatory == "TRUE" then
               mandatory = true
            else
               mandatory = false
            end
            
            exclude     = nil

            loi.attributes.each_attribute{|attr|
               if attr.name == "exclude" then
                  exclude = loi.attributes["exclude"]
               end
            }
            @ListOfInputs << fillListOfInputs(dataType, coverage_, mandatory, exclude)
         }

         arr << fillProcessRule(output, triggerInput, coverage, executable, @ListOfInputs)
         @ListOfInputs = Array.new

      }

      @@arrOrchProcessRule = arr

   end
   #-------------------------------------------------------------------------


   # Process File, Miscelanea Module
   # - xmlFile (IN): XML file
   def parseProcParameters(xmlFile)

      @@listOfProcParameters = Array.new
      name  = nil
      value = nil
      unit  = nil

      XPath.each(xmlFile, "OrchestratorConfiguration/List_of_Parameters/Parameter"){
         |procParam|
         
         # Get Processing Parameters
         name        = procParam.attributes["name"]
         value       = procParam.attributes["value"]
         unit        = procParam.attributes["unit"]

         @@listOfProcParameters << fillProcParameter(name, value, unit)
      }
   end
   # -------------------------------------------------------------------------


   # Process File, Miscelanea Module
   # - xmlFile (IN): XML file
   def parseMiscelanea(xmlFile)

      archiveHandler = nil
      pollingDir     = ""
      pollingFreq    = ""
      parallelIngest = 1
      procWorkingDir = ""
      successDir     = ""
      failureDir     = ""
      breakPointDir  = ""
      tmpDir         = ""

   # for each data provider...
      XPath.each(xmlFile,"OrchestratorConfiguration/Miscelanea"){
         |mc|
            #gets the 9 children on the xml tree
      archiveHandler    = mc.elements[1].text
      pollingDir        = mc.elements[2].text
      pollingFreq       = mc.elements[3].text
      parallelIngest    = mc.elements[4].text.to_i
      schedulingFreq    = mc.elements[5].text
      resourceManager   = mc.elements[6].text
      procWorkingDir    = mc.elements[7].text
      successDir        = mc.elements[8].text
      failureDir        = mc.elements[9].text
      breakPointDir     = mc.elements[10].text
      tmpDir            = mc.elements[11].text

      @@miscelanea = fillMiscelanea(archiveHandler, pollingDir, pollingFreq, parallelIngest, schedulingFreq, resourceManager, procWorkingDir, successDir, failureDir, breakPointDir, tmpDir)
      }
      
      
 

   end 
   ## ---------------------------------------------------------------

   def parseInventory(xmlFile)
   
      ## -----------------------------------------
      ## Process Inventory Configuration
      XPath.each(xmlFile, "OrchestratorConfiguration/Inventory"){      
         |inventory|

         db_adapter  = ""
         db_host     = ""
         db_port     = ""
         db_name     = ""
         db_user     = ""
         db_pass     = ""

         XPath.each(inventory, "Database_Adapter"){
            |adapter|  
            db_adapter = adapter.text.to_s
         }

         XPath.each(inventory, "Database_Host"){
            |name|
            db_host  = name.text.to_s
         }

         XPath.each(inventory, "Database_Port"){
            |name|
            db_port  = name.text.to_s
         }
         
         XPath.each(inventory, "Database_Name"){
            |name|
            db_name  = name.text.to_s
         }

         XPath.each(inventory, "Database_User"){
            |user|
            db_user  = user.text.to_s
         }

         XPath.each(inventory, "Database_Password"){
            |pass|
            db_pass  = pass.text.to_s   
         }
         
         @inventory = Struct::Inventory.new(db_adapter, \
                                             db_host, \
                                             db_port, \
                                             db_name, \
                                             db_user, \
                                             db_pass)
          
      }
      ## -----------------------------------------

   end

   ## -----------------------------------------------------------

   ## Check that everything needed is present
   def checkModuleIntegrity

      bDefined = true
      bCheckOK = true

      if !ENV['ORC_CONFIG'] then
        puts "\nORC_CONFIG environment variable not defined !  :-(\n\n"
        bCheckOK = false
        bDefined = false
      end

      if bDefined == true
      then
        configDir         = %Q{#{ENV['ORC_CONFIG']}}
        @@configDirectory = configDir

        configFile = %Q{#{configDir}/orchestratorConfigFile.xml}
        if !FileTest.exist?(configFile) then
           bCheckOK = false
           print("\n\n", configFile, " does not exist !  :-(\n\n" )
        end

      end
      if bCheckOK == false then
        puts "ORC_ReadOrchestratorConfig::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end
   end
   ## -----------------------------------------------------------

end # class

end # module
