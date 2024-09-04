#!/usr/bin/env ruby

#
# == Usage
# minADbUpdate.rb --up | --down
#     --up     update minarc tables for orchestrator needs
#     --down   roll back to standard minarc tables
#     --help   shows this help
# 
# == Author
# DEIMOS-Space S.L.
#
# == Copyright
# Copyright (c) 2008 ESA - DEIMOS Space S.L.
#

require 'getoptlong'
require 'rdoc/usage'

require "rubygems"
require "active_record"

dbAdapter   = ENV['MINARC_DB_ADAPTER']
dbName      = ENV['MINARC_DATABASE_NAME']
dbUser      = ENV['MINARC_DATABASE_USER']
dbPass      = ENV['MINARC_DATABASE_PASSWORD']

ActiveRecord::Base.establish_connection(:adapter => dbAdapter,
         :host => "localhost", :database => dbName,
         :username => dbUser, :password => dbPass)

#=====================================================================

class ArchiveUpdater < ActiveRecord::Migration

   def self.up
      add_column(:archived_files, :trigger_product_name, :string)
   end

   def self.down
      remove_column(:archived_files, :trigger_product_name)
   end

end

#=====================================================================

# MAIN script function
def main

   bUp   = false
   bDown = false
   
   opts = GetoptLong.new(
     ["--up",   "-u",           GetoptLong::NO_ARGUMENT],
     ["--down", "-d",           GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--up"        then @bUp   = true
            when "--down"      then @bDown = true
			   when "--help"      then RDoc::usage
         end
      end
   rescue Exception
      exit(99)
   end

   if @bDown and @bUp then
      RDoc::usage("usage")
   end

   if @bDown then
      ArchiveUpdater.down
      exit(0)
   end

   if @bUp then
      ArchiveUpdater.up
      exit(0)
   end

   RDoc::usage("usage")
 
   exit(0)

end

#=====================================================================
# Start of the main body
main
# End of the main body
#=====================================================================
