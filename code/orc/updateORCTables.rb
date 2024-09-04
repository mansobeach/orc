#!/usr/bin/env ruby

require "rubygems"
require "active_record"

dbAdapter   = ENV['ORC_DB_ADAPTER']
dbName      = ENV['ORC_DATABASE_NAME']
dbUser      = ENV['ORC_DATABASE_USER']
dbPass      = ENV['ORC_DATABASE_PASSWORD']

ActiveRecord::Base.establish_connection(:adapter => dbAdapter,
         :host => "localhost", :database => dbName,
         :username => dbUser, :password => dbPass)


puts "START"

ActiveRecord::Migration.add_column("failing_trigger_products", "failure_date", "datetime")

ActiveRecord::Migration.add_column("successful_trigger_products", "success_date", "datetime")

puts "END"
