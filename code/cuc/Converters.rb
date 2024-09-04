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

module CUC

module Converters

   ## -----------------------------------------------------------
   
   ## String formats supported:
   ## - 22 731                       => "%y%m%d"   / Length 6
   ## - 2017JAN                      => "%Y%b"     / Length 7
   ## - 20120325                     => "%Y%m%d"   / Length 8
   ## - 2012  3 25                   => "%Y %m %d" / Length 10
   ## - 2017 JAN  1                  => "%Y %b %d" / Length 11
   ## - 20120325T154814              => "%Y%m%dT%H%M%S" / Length 15            => XL_ASCII_CCSDSA_COMPACT
   ## - 2017-04-22T11:02:57.045757   => "%Y-%m-%dT%H:%M:%S.%6N" / Length 26    => XL_ASCII_CCSDSA_MICROSEC
   ## - 21-MAY-2015 14:00:01.516     => "%e-%b-%Y %H:%M:%S.%L"  / Length 24
   ## - 01-FEB-2016 02:20:40.59      => "%e-%b-%Y %H:%M:%S.%L"  / length 23
   ## - 01-FEB-2016 02:20:40.5       => "%e-%b-%Y %H:%M:%S.%L"  / length 22
   ## - 22-FEB-2016 15:13:08         => "%e-%b-%Y %H:%M:%S"     / length 20
   ## - 2015-11-16T00:30:27          => "%Y-%m-%dT%H:%M:%S"
   ## - 2020-05-15T00:00:00.000Z     => "%Y-%m-%dT%H:%M:%S"     / length 24
   ## - 2020-05-15T00:00:00.000      => "%Y-%m-%dT%H:%M:%S"     / length 23
   
   def str2date(str)
   
      if (str.length == 26) and str.slice(4,1) == "-" and str.slice(7,1) == "-" and str.include?("T") then
         return DateTime.strptime(str,"%Y-%m-%dT%H:%M:%S.%N")
      end
  
      if (str.length == 24 or str.length == 23 or str.length ==22) and str.slice(2,1) == "-" and str.slice(6,1) == "-" then
         return DateTime.strptime(str,"%e-%b-%Y %H:%M:%S.%L")
      end

      if (str.length == 24 or str.length == 23 or str.length ==22) and str.slice(2,1) == "-" and str.slice(6,1) == "-" then
         return DateTime.strptime(str,"%e-%b-%Y %H:%M:%S.%L")
      end

      if (str.length == 20) and str.slice(2,1) == "-" and str.slice(6,1) == "-" then
         return DateTime.strptime(str,"%e-%b-%Y %H:%M:%S")
      end

      begin
         if str.length == 19 and str.include?("T") then
            return DateTime.strptime(str,"%Y-%m-%dT%H:%M:%S")
         end
      rescue Exception => e
         puts e.to_s
         puts
         puts str
         puts
         exit(99)
      end

      begin
         if (str.length == 24 or str.length == 23) and str.include?("T") then
            return DateTime.strptime(str,"%Y-%m-%dT%H:%M:%S")
         end
      rescue Exception => e
         puts e.to_s
         puts
         puts str
         puts
         exit(99)
      end

      begin
         if str.length == 15 and str.include?("T") then
            return DateTime.strptime(str,"%Y%m%dT%H%M%S")
         end
      rescue Exception => e
         puts e.to_s
         puts
         puts str
         puts
         exit(99)
      end
     
      if str.length == 14 then
         return DateTime.strptime(str,"%Y%m%d%H%M%S")
      end

      if str.length == 11 then
         return DateTime.strptime(str,"%Y %b %d")
      end

      if str.length == 10 then
         return DateTime.strptime(str,"%Y %m %d")
      end

      if str.length == 8 then
         return DateTime.strptime(str,"%Y%m%d")
      end
     
      if str.length == 7 then
         return DateTime.strptime(str,"%Y%b")
      end

      if str.length == 6 then
         return DateTime.strptime(str,"%y%m%d")
      end

      ## ---------------------------------------- 
      ## This is going to cause problems
      if str.length == 6 then
         return DateTime.new(str.slice(0,4).to_i, str.slice(4,2).to_i)
      end
      ## ---------------------------------------- 
      
      raise "FATAL ERROR in CUC::Converters str2date(#{str}) / length #{str.length}"

=begin
      puts
      puts "FATAL ERROR in CUC::Converters str2date(#{str}) / length #{str.length}"
      puts
      puts
      exit(99)

      return DateTime.new(str.slice(0,4).to_i, str.slice(4,2).to_i, str.slice(6,2).to_i,
                          str.slice(9,2).to_i,  str.slice(11,2).to_i, str.slice(13,2).to_i)
=end

   end

   ## -----------------------------------------------------------

   ## output string shall follow this format 2015-06-18T12:23:27
   ## - 2015-04-02T16:36:14.339
   ## - 2015-06-27T14:24:34.000000
   ## - 2015-06-19T21:14:10Z
   ## - 2015-06-27T09:07:06Z;DET=123456789ABC       / More rubbish from E2ESPM
   ## - 2015-06-27T14:24:34.000000;DET=123456789ABC / More rubbish from E2ESPM
   ## - 2015-04-02T16:36:14.339Z / Another one from E2ESPM
   ## - 2015-04-02T16:36:14.3Z   / Another one from E2ESPM
   def str2strexceldate(str)
#       puts str
#       puts str.length
#       puts str.slice(19,1)
#       puts str.slice(7,1)
#       puts str.slice(19,1)


      # - 2015-06-27T14:24:34.000000
      if str.length == 26 and str.slice(19,1) == "." and str.slice(4,1) == "-" and
          str.slice(7,1) == "-" and str.slice(10,1) == "T" then
         return str.slice(0, 19)
      end


      # - 2015-06-27T14:24:34.000000;DET=123456789ABC
      if str.length > 26 and str.slice(19,1) == "." and str.slice(4,1) == "-" and
          str.slice(7,1) == "-" and str.slice(10,1) == "T" then
         return str.slice(0, 19)
      end

      
      # - 2015-04-02T16:36:14.339
      if str.length == 23 and str.slice(19,1) == "." and str.slice(4,1) == "-" and
          str.slice(7,1) == "-" and str.slice(10,1) == "T" then
         return str.slice(0, 19)
      end
      
      # - 2015-06-19T21:14:10Z
      
      if str.length == 20 and str.slice(19,1) == "Z" and str.slice(4,1) == "-" and
          str.slice(7,1) == "-" and str.slice(10,1) == "T" then
         return str.slice(0, 19)
      end

      # - 2015-06-19T21:14:10

      if str.length == 19 and str.slice(4,1) == "-" and
          str.slice(7,1) == "-" and str.slice(10,1) == "T" then
         return str.slice(0, 19)
      end


       # - 2015-06-27T09:07:06Z;DET=123456789ABC
      
      if str.length > 20 and str.slice(19,1) == "Z" and str.slice(4,1) == "-" and
          str.slice(7,1) == "-" and str.slice(10,1) == "T" then
         return str.slice(0, 19)
      end

      # - 2015-04-02T16:36:14.339Z
      if str.length == 24 and str.slice(19,1) == "." and str.slice(4,1) == "-" and
          str.slice(7,1) == "-" and str.slice(10,1) == "T" and str.slice(23,1) == "Z" then
         return str.slice(0, 19)
      end
 
       # - 2015-04-02T16:36:14.3Z
      if str.length == 22 and str.slice(19,1) == "." and str.slice(4,1) == "-" and
          str.slice(7,1) == "-" and str.slice(10,1) == "T" and str.slice(21,1) == "Z" then
         return str.slice(0, 19)
      end
      
      puts
      puts "FATAL ERROR in CUC::Converters str2strexceldate( #{str} / length #{str.length}  )"
      puts
      puts
      exit(99)
      
   end
   ## -----------------------------------------------------------

   def str2time(str)
      return Time.local(str.slice(0,4).to_i, str.slice(4,2).to_i, str.slice(6,2).to_i,
                          str.slice(9,2).to_i,  str.slice(11,2).to_i, str.slice(13,2).to_i)

   end
   ## -----------------------------------------------------------

   def str_to_bool(str)
      return true   if str == true   || str =~ (/(true|t|yes|y|1)$/i)
      return false  if str == false  || str.empty? || str =~ (/(false|f|no|n|0)$/i)
      raise ArgumentError.new("Converters::str_to_bool invalid value for Boolean: \"#{str}\"")
   end
   ## -----------------------------------------------------------

   ## sdm_mjd2000_to_utc -d 6600.04170138889
   def mjd2000_to_utc(str)
      days        = (str.to_f.to_i)*86400
      remainder   = "0.#{str.to_s.split('.')[1]}".to_f*86400
      epoch       = Time.utc(2000,"jan",1,00,00,00).to_i
      return Time.at(epoch+days+remainder).utc 
   end
   ## -----------------------------------------------------------

   def utc_to_mjd2000(str)
      epoch    = DateTime.strptime("20000101T000000","%Y%m%dT%H%M%S")
      dateUTC  = str2date(str)
      mjd200   = dateUTC - epoch
      return mjd200
   end
   ## -----------------------------------------------------------

   ## XL_ASCII_CCSDSA_COMPACT
   def strDateMidnight
      return "#{Date.today.strftime("%Y%m%dT")}000000"
   end
   ## -----------------------------------------------------------

   ## XL_ASCII_CCSDSA_COMPACT
   def strDateNow
      return "#{Date.today.strftime("%Y%m%dT%H%M%S")}"
   end
   ## -----------------------------------------------------------

   ### http://www.csgnetwork.com/julianmodifdateconv.html

   def strMJD2Date(mjd)
      return Date.jd(2400000.5 + mjd).strftime("%Y%m%dT%H%M%S")
   end
   
   ## -----------------------------------------------------------

end # module

end # module
