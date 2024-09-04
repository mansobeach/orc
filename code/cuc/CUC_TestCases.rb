#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #MINARC_TestCases class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Mini Archive Component (MinArc)
# 
# module MINARC
#
#########################################################################

require 'rubygems'
require 'test/unit'

require 'cuc/Converters'


class TestCaseStore < Test::Unit::TestCase

   include CUC::Converters

   # Order of the test cases execution according to defintion within code
   self.test_order = :defined
   
   #--------------------------------------------------------
   
   Test::Unit.at_start do
      puts "Begin of tests"
   end
   
   #--------------------------------------------------------
   
   Test::Unit.at_exit do
      puts "End of tests"
   end
   
   #--------------------------------------------------------   
   
   # Setup before every test-case
   #
   def setup
   end
   #--------------------------------------------------------
   # After every test case

   def teardown
   end
   #--------------------------------------------------------


   #-------------------------------------------------------------

   def test_Converters_mjd2000_to_date
      puts
      puts "================================================"
      puts "Converters::mjd2000_to_date"
      puts
      value = "6600.04170138889"
      puts value
      
      puts mjd2000_to_utc(value)
      
   end
   #--------------------------------------------------------


   #-------------------------------------------------------------

end


#=====================================================================


#-----------------------------------------------------------


