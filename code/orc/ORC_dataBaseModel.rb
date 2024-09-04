#!/usr/bin/env ruby

require "rubygems"
require "active_record"

dbAdapter   = ENV['ORC_DB_ADAPTER']
dbName      = ENV['ORC_DATABASE_NAME']
dbUser      = ENV['ORC_DATABASE_USER']
dbPass      = ENV['ORC_DATABASE_PASSWORD']

ActiveRecord::Base.establish_connection(:adapter => dbAdapter,
         :host => "tmp", :database => dbName,
         :username => dbUser, :password => dbPass)
#---------------

class Pending2QueueFile < ActiveRecord::Base
   set_table_name :pending2queue_files
   validates_presence_of   :filename
   validates_presence_of   :filetype
   validates_presence_of   :detection_date
end

def main
   
   tupla  = Pending2queue_file.new
   tupla.filename = "Prueba2"
   tupla.filetype = "Tipo2"
   tupla.detection_date = "11/11/2000"
   tupla.save
end

main

