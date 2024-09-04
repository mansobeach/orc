#!/usr/bin/env ruby

#########################################################################
#
# ===       
#
# === Written by Borja Lopez Fernandez
#
# === Casale & Beach
# 
#
#
#########################################################################

require 'rubygems'

require 'date'

require 'cuc/Converters'

module CUC

class WrapperExifTool

   include CUC::Converters

   ## ------------------------------------------------  
   
   ## Class contructor
   ## 
   def initialize(fullpathfile, debugMode = false)
      @fullpathfile        = fullpathfile
      @isDebugMode         = debugMode
      @cmd                 = "exiftool -api largefilesupport=1 #{@fullpathfile}"
      @result              = `#{@cmd}`
      if @isDebugMode == true then
         puts @cmd
         puts @result
      end
      checkModuleIntegrity
   end
   ## ------------------------------------------------
   
   ## Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "WrapperExifTool debug mode is on"
   end
   ## ------------------------------------------------

   ## 
   def date_time_original
      str = nil
      
      begin
         str   = @result.split("Date/Time Original")[1].lines[0].strip
      rescue Exception
         puts "Error in WrapperExifTool / Could not retrieve metadata Date/Time Original"
         return nil
      end
      
      str   = str.slice(2, str.length-1)
      year  = str.slice(0, 4)
      month = str.slice(5, 2)
      day   = str.slice(8, 2)
      hour  = str.slice(11,2)
      min   = str.slice(14,2)
      sec   = str.slice(17,2)
      strDate = "#{year}#{month}#{day}T#{hour}#{min}#{sec}"
      
      return str2time(strDate)
      
   end
   ## ------------------------------------------------

   ## 
   def create_date
      str = nil
      
      begin
         str   = @result.split("Create Date")[1].lines[0].strip
      rescue Exception
         puts "Error in WrapperExifTool / Could not retrieve metadata Create Date"
         return nil
      end
      
      str   = str.slice(2, str.length-1)
      year  = str.slice(0, 4)
      month = str.slice(5, 2)
      day   = str.slice(8, 2)
      hour  = str.slice(11,2)
      min   = str.slice(14,2)
      sec   = str.slice(17,2)
      strDate = "#{year}#{month}#{day}T#{hour}#{min}#{sec}"
      
      return str2time(strDate)
      
   end
 

   ## ------------------------------------------------

   ## 
   def creation_date
      str = nil
      
      begin
         str   = @result.split("Creation Date")[1].lines[0].strip
      rescue Exception
         puts "Error in WrapperExifTool / Could not retrieve metadata Creation Date"
         return nil
      end
      
      str   = str.slice(2, str.length-1)
      year  = str.slice(0, 4)
      month = str.slice(5, 2)
      day   = str.slice(8, 2)
      hour  = str.slice(11,2)
      min   = str.slice(14,2)
      sec   = str.slice(17,2)
      strDate = "#{year}#{month}#{day}T#{hour}#{min}#{sec}"
      
      return str2time(strDate)
      
   end
 
   ## ------------------------------------------------

   def width
      str = nil
      
      begin
         str   = @result.split("Image Width")[1].lines[0].strip.split(":")[1].strip
      rescue Exception
         puts "Error in WrapperExifTool / Could not retrieve metadata Image Width"
         return nil
      end
    
      return str.to_i
    
   end
   ## ------------------------------------------------

   def height
      str = nil
      
      begin
         str   = @result.split("Image Height")[1].lines[0].strip.split(":")[1].strip
      rescue Exception
         puts "Error in WrapperExifTool / Could not retrieve metadata Image Height"
         return nil
      end
    
      return str.to_i
    
   end
   ## ------------------------------------------------

   def duration
      str = nil
      
      begin
         str   = @result.split("Duration")[1].lines[0].strip.split(" ")[1]
      rescue Exception
         puts "Error in WrapperExifTool / Could not retrieve metadata Duration"
         return nil
      end
    
#      dt = DateTime.parse(str)
#      return dt.hour * 3600 + dt.min * 60 + dt.sec
    
      return str
    
   end
   ## ------------------------------------------------

private

   # -------------------------------------------------------------
   # Check that everything needed by the class is present.
   # -------------------------------------------------------------
   def checkModuleIntegrity
      return
   end
   # --------------------------------------------------------
   
end # class

end # module
