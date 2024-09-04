#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #ReportQueuedFiles class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === ORCHESTRATOR tools
# 
# CVS: $Id: ReportQueuedFiles.rb,v 1.1 2008/06/04 10:10:01 decdev Exp $
#
# module ORC
#
#########################################################################

require "cuc/DirUtils"
require "orc/ORC_DataModel"
require "rexml/document"

module ORC

class ReportQueuedFiles

   include CUC::DirUtils
   include REXML

   #-------------------------------------------------------------
   
   # Class constructor.
   # IN Parameters:
   def initialize(reportName)
      @fullpathreportName = reportName
		checkModuleIntegrity
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "ReportQueuedFiles debug mode is on"
   end
   #-------------------------------------------------------------

   # Main class method
   # It writes the data to the report.
   def write(data)
      writeReport(data)
   end
   #-------------------------------------------------------------

private

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      return
   end
   #-------------------------------------------------------------

   def writeReport(data)
         
      doc = Document.new 
      doc.add_element 'ORC_Report'
      doc << XMLDecl.new

      # First Section : file names
      efileList = Element.new "List_of_TriggerFiles"
      
      data.each{|aFile|
         eTmpName = Element.new "Name"
         eTmpName.attributes["detectionDate"] = aFile.detection_date.strftime("%Y%m%dT%H%M%S")
         eTmpName.attributes["initialStatus"] = aFile.initial_status
         eTmpName.text = aFile.filename
         efileList.elements << eTmpName
      }
      
      doc.root.elements << efileList

      file = File.open(@fullpathreportName, "w")
      doc.write(file, 2)
      file.close
   end
   #-------------------------------------------------------------


end # class

end # module
