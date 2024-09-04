#!/usr/bin/ruby

#########################################################################
#
# Ruby source for #ReadServiceConfig class          
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Collector Component
# 
# CVS:
#  $Id: ReadServiceConfig.rb,v 1.1 2006/09/12 07:59:26 decdev Exp $
#
#########################################################################

require 'singleton'
require 'rexml/document'
require 'cuc/DirUtils'

 # This class processes dcc_services.xml config file
 # which contains external processes to be executed with a given frequency.

class DCC_ReadService

   include Singleton
   include REXML
   include CUC::DirUtils
   #-------------------------------------------------------------
  
   # Class constructor
   def initialize()
      @@isModuleOK        = false
      @@isModuleChecked   = false 
      @isDebugMode        = false
      @@handlerXmlFile    = nil      
      checkModuleIntegrity
		defineStructs
      @@arrServices = Array.new
      loadData
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "ReadServiceConfig debug mode is on"
   end
   #-------------------------------------------------------------
   
   # Get the services
   def services
      return @@arrServices
   end
   #-------------------------------------------------------------
   
   def getCommand(serviceName)
      @@arrServices.each{|service|
         if service[:name] == serviceName then
            return service[:command]
         end
      }
      return false
   end
   #-------------------------------------------------------------
   
   def getNameServices
      arrNames = Array.new
      @@arrServices.each{|service|
         arrNames << service[:name]
      }
      return arrNames
   end
   #-------------------------------------------------------------
   
   def getInterval(serviceName)
      @@arrServices.each{|service|
        if service[:name] == serviceName then
            return service[:interval]
         end
      }
      return false         
   end
   #-------------------------------------------------------------
   
   def exist?(serviceName)
      @@arrServices.each{|service|
         if service[:name] == serviceName then
            return true
         end
      }
      return false   
   end
   #-------------------------------------------------------------
private

   @@isModuleOK        = false
   @@isModuleChecked   = false
   @isDebugMode        = false
   @@configDirectory   = ""
   

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      
      bDefined = true
      bCheckOK = true
   
      if !ENV['DCC_CONFIG'] then
         puts "DCC_CONFIG environment variable not defined !  :-(\n"
         bCheckOK = false
         bDefined = false
      end
           
      if bDefined == true then      
         configDir         = %Q{#{ENV['DCC_CONFIG']}}        
         @@configDirectory = configDir
        
         @@configFile = %Q{#{@@configDirectory}/dcc_services.xml}        
         if !FileTest.exist?(@@configFile) then
            bCheckOK = false
            print("\n\n", @@configFile, " does not exist !  :-(\n\n" )
         end           
      end
         
      if bCheckOK == false then
        puts "ReadServiceConfig::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end      
   end
   #-------------------------------------------------------------
	
   # This method creates all the structs used
	def defineStructs
	   Struct.new("Service", :name, :desc, :command, :interval)
	end
	#-------------------------------------------------------------

   # Load the file into the an internal struct.
   #
   # The struct is defined in the class Constructor. See #initialize.
   def loadData
      externalFilename = @@configFile
      fileExternal     = File.new(externalFilename)
      xmlFile          = REXML::Document.new(fileExternal)
      @@arrServletsServices = Array.new    
      if @isDebugMode == true then
         puts "\nProcessing #{@@configFile}"
      end
      process(xmlFile)     
   end   
   #-------------------------------------------------------------
   
   # Process the xml file decoding all the file
   # - xmlFile (IN): XML configuration file
   def process(xmlFile)
#      setDebugMode
      aDescription         = ""
      aName                = ""
      aCommand             = ""
      anInterval           = ""

      #----------------------------------------
      # Services List Processing
      path    = "Services/Service"
      
      services = XPath.each(xmlFile, path){
          |service|

          XPath.each(service, "Name"){
             |name|
             aName = name.text
          }
                    
          XPath.each(service, "Desc"){
             |desc|
             aDescription = desc.text
          }
  
          XPath.each(service, "Command"){
             |command|
             aCommand = command.text
          }
          
          XPath.each(service, "Interval"){
             |interval|
             anInterval = interval.text
          }	  
     
          @@arrServices << fillServiceStruct(aName, aDescription, aCommand, anInterval)
          
          
      }
      #----------------------------------------
        
   end
   #-------------------------------------------------------------
   
   # Fill a Service struct
   # - aDescription (IN)  :  DIM name
   # - aCommand    (IN)   :  DIM Intray directory
   # There is only one point in the class where all dynamic structs 
   # are filled so that it is easier to update/modify the I/F.
   def fillServiceStruct(aName, aDescription, aCommand, anInterval)
      if @isDebugMode == true then
         puts "===================================="
         puts "Name    : #{aName} "
         puts "Desc    : #{aDescription} "
         puts "Command : #{aCommand}"
         puts "Interval: #{anInterval}"
         puts "===================================="
      end
    
      # Avoid Services duplication
      @@arrServices.each{|service|
             if service[:name] == aName then
                puts "ERROR in #{@@configFile} file !"
                puts "#{aName} is duplicated in the Service"
                puts "Please check your configuration file"
                puts
                exit(99)
             end
      }
      
      tmpStruct = Struct::Service.new(aName,
                                 aDescription,
                                 aCommand,
                                 anInterval)   		
      return tmpStruct
   end
   #-------------------------------------------------------------    

end
