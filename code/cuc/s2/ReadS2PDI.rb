#!/usr/bin/ruby

#########################################################################
#
# Ruby source for #ReadS2PDI class          
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Collector Component
# 
#
#########################################################################

require 'rexml/document'
require 'cuc/DirUtils'

 # This class parses a Sentinel-2 PDGS s2pdi file

module S2

class ReadS2PDI

   include REXML
   include CUC::DirUtils
   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(filename)
      @filename            = filename
      @isModuleOK          = false
      @isModuleChecked     = false 
      @isDebugMode         = false
      @handlerXmlFile      = nil
      
      
      checkModuleIntegrity
		
      @@arrServices = Array.new
      loadData
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "ReadS2PDI debug mode is on"
   end
   #-------------------------------------------------------------
   
   # Get the array of LogicalIdentifier (PDI)
   def getPDIs
      return @arrPDI
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
private

   @isModuleOK        = false
   @isModuleChecked   = false
   @isDebugMode       = false
   @@configDirectory  = ""
   

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
            
      bDefined = true
      bCheckOK = true
   
      if !FileTest.exist?(@filename) then
         bCheckOK = false
         print("\n\n", @filename, " does not exist !  :-(\n\n" )
      end           
      
         
      if bCheckOK == false then
         puts "ReadS2PDI::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end      
   end
   #-------------------------------------------------------------
	
	#-------------------------------------------------------------

   # Load the file into the an internal struct.
   #
   # The struct is defined in the class Constructor. See #initialize.
   def loadData
      fileExternal     = File.new(@filename)
      xmlFile          = REXML::Document.new(fileExternal)
      if @isDebugMode == true then
         puts "\nProcessing #{@filename}"
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

      @arrPDI              = Array.new

      #----------------------------------------
      # Services List Processing
      path    = "dagc:UserProductDownloadRequest/List_Of_LogicalIdentifiers/"
      
      services = XPath.each(xmlFile, path){
          |list_s2pdi|
          
#           puts list_s2pdi
#           next

          XPath.each(list_s2pdi, "LogicalIdentifier"){
             |logical|
             aName = logical.text
             # puts aName
             @arrPDI << aName
          }
      }
      #----------------------------------------
        
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------    


end # class

end # module

