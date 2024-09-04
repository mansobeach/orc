#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #EE_DateConverter class         
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === MDS-LEGOS => ORC Component
# 
# CVS: $Id: EE_DateConverter.rb,v 1.3 2009/05/06 13:24:33 decdev Exp $
#
# This class is used to convert different date formats commonly used.
# following the Earth Explorer filename conventions
#
#########################################################################

 
module CUC

module EE_DateConverter

   #-------------------------------------------------------------
   
   # This method returns a job-order date format string
   # "2050-01-01 000000.000"
   def convert2JobOrderDate(aDate)
      
      strResult = ""
      arrConversion = aDate.split('+')
            
      if arrConversion.length > 1 then
         strResult = arrConversion[0].sub('T', ' ')
         strResult = strResult.sub(':', '')
         strResult = strResult.sub(':', '')
         strResult = "#{strResult}.000"
         return strResult
      else
         strResult = arrConversion[0]
                 
         if strResult.length == 15 then
            strResult = arrConversion[0].sub('T', ' ')
            strResult = "#{strResult}.000"
            year      = strResult.slice(0,4)
            month     = strResult.slice(4,2)
            day       = strResult.slice(6,2)
            rest      = strResult.split(' ')[1]
            strResult = "#{year}-#{month}-#{day} #{rest}"
            return strResult
         end
         
         if strResult.length == 21 then
            return strResult.to_s
         else
            puts
            puts "Error in EE_DateConverter::convert2JobOrderDate"
            puts
            puts strResult
            puts strResult.length
            puts
            exit(99)
         end
      end
   end
   #-------------------------------------------------------------

   # This method returns a job-order date format string
   # "20500101T000000"
   def convert2EEString(aDate)
      strResult = ""
      arrConversion = aDate.split('+')
      if arrConversion.length > 0 then
         strResult = arrConversion[0]
         strResult = strResult.sub('-', '')
         strResult = strResult.sub('-', '')
         strResult = strResult.sub(':', '')
         strResult = strResult.sub(':', '')
         return strResult
      else
         return aDate
         puts "Error in EE_DateConverter::convert2EEString"
         exit(99)
      end
   end   
   #-------------------------------------------------------------

end # module EE_DateConverter

end # module CUC
