#!/usr/bin/env ruby


require 'rubygems'
require 'active_record'

dbAdapter   = ENV['ORC_DB_ADAPTER']
dbName      = ENV['ORC_DATABASE_NAME']
dbUser      = ENV['ORC_DATABASE_USER']
dbPass      = ENV['ORC_DATABASE_PASSWORD']

ActiveRecord::Base.establish_connection(
                                          :adapter    => dbAdapter,
                                          :host       => "localhost", 
                                          :database   => dbName,
                                          :username   => dbUser, 
                                          :password   => dbPass, 
                                          :timeout    => 100000,
                                          :cast       => false,
                                          :pool       => 10
                                          )

## ===================================================================

class CreateTriggerProducts < ActiveRecord::Migration[6.0]
   def self.up
      create_table(:trigger_products) do |t|
         t.index  :id
         t.column :filename,            :string,  :limit => 100
         t.index  :filename
         t.column :filetype,            :string,  :limit => 20
         t.column :detection_date,      :datetime
         t.column :sensing_start,       :datetime
         t.column :sensing_stop,        :datetime
         t.column :runtime_status,      :string, :limit => 3 
         t.column :initial_status,      :string, :limit => 3
      end
   end

   def self.down
      drop_table :trigger_products
   end
end

## ===================================================================

class CreateOrchestratorQueue < ActiveRecord::Migration[6.0]
  
   def self.up
      create_table(:orchestrator_queue, :id => false) do |t|
         t.column       :filename,            :string,  :limit => 100
         t.index        :filename
         t.column       :filetype,            :string,  :limit => 20
         t.column       :queue_date,          :datetime

         t.primary_key :trigger_product_id
      end
      add_foreign_key :orchestrator_queue, :trigger_products
   end

   def self.down
      drop_table :orchestrator_queue
   end
end

## ===================================================================

class CreateFailingTriggerProducts < ActiveRecord::Migration[6.0]
   
   def self.up
      create_table(:failing_trigger_products, :id => false) do |t|
         t.primary_key :trigger_product_id
         t.column      :failure_date,      :datetime
      end
      add_foreign_key :failing_trigger_products, :trigger_products
   end

   def self.down
      drop_table :failing_trigger_products
   end
end

## ===================================================================

class CreateSuccessfulTriggerProducts < ActiveRecord::Migration[6.0]

   def self.up
      create_table(:successful_trigger_products, :id => false) do |t|
         t.primary_key :trigger_product_id
         t.column      :success_date,      :datetime
      end
      add_foreign_key :successful_trigger_products, :trigger_products 
   end

   def self.down
      drop_table :successful_trigger_products
   end
end

## ===================================================================

class CreateDiscardedTriggerProducts < ActiveRecord::Migration[6.0]

   def self.up
      create_table(:discarded_trigger_products, :id => false) do |t|
         t.primary_key :trigger_product_id
         t.column      :discarded_date,      :datetime
      end
      add_foreign_key :discarded_trigger_products, :trigger_products
   end

   def self.down
      drop_table :discarded_trigger_products
   end
end

## =====================================================================

class CreateObsoleteTriggerProducts < ActiveRecord::Migration[6.0]

   def self.up
      create_table(:obsolete_trigger_products, :id => false) do |t|
         t.primary_key :trigger_product_id
         t.column      :obsolete_date,      :datetime
      end
      add_foreign_key :obsolete_trigger_products, :trigger_products
   end

   def self.down
      drop_table :obsolete_trigger_products
   end
end

## =====================================================================

class CreatePending2QueueFiles < ActiveRecord::Migration[6.0]
   def self.up
      create_table(:pending2queue_files, :id => false) do |t|
         t.primary_key  :trigger_product_id
         t.column       :filename,            :string,  :limit => 100
         t.index        :filename
         t.column       :filetype,            :string,  :limit => 20
         t.column       :detection_date,      :datetime
      end
      add_foreign_key :pending2queue_files, :trigger_products
   end

   def self.down
      drop_table :pending2queue_files
   end
end

## =====================================================================

#class CreatePending2QueueFiles_OLD_TO_BE_REMOVED < ActiveRecord::Migration[6.0]
#   def self.up
#      create_table(:pending2queue_files) do |t|
#         t.column :filename,            :string,  :limit => 100
#         t.column :filetype,            :string,  :limit => 20
#         t.column :detection_date,      :datetime
#      end
#   end
#
#   def self.down
#      drop_table :pending2queue_files
#   end
#end

## =====================================================================

# class CreateGeneratedProducts < ActiveRecord::Migration
#    extend MigrationHelpers
# 
#    def self.up
#       create_table(:generated_products) do |t|
#          t.column :filename,           :string,  :limit => 100
#          t.column :filetype,           :string,  :limit => 20
#          t.column :generation_date,    :datetime
#          t.column :sensing_start,      :datetime
#          t.column :sensing_stop,       :datetime
#          t.column :trigger_product_id, :integer, :limit => 38
#       end
#       foreign_key(:generated_products, :trigger_product_id, :trigger_products, 5)
#    end
# 
#    def self.down
#       drop_table :generated_products
#    end
# end

class CreateProductionTimelines < ActiveRecord::Migration[6.0]
   def self.up
      create_table(:production_timelines) do |t|
         t.column :file_type,      :string
         t.column :sensing_start,  :datetime
         t.column :sensing_stop,   :datetime
      end
   end

   def self.down
      drop_table :production_timelines
   end
end

## ===================================================================

class CreateRunningJobs < ActiveRecord::Migration[6.0]
   def self.up
      create_table(:running_jobs) do |t|
         t.column :proc_id,     :integer
         t.column :joborder_id, :integer
      end
   end

   def self.down
      drop_table :running_jobs
   end
end

## ===================================================================


## ===================================================================

class CreateOrchestratorMessages < ActiveRecord::Migration[6.0]
   def self.up
      create_table(:orchestrator_messages) do |t|
         t.column :source_type,      :string,   :limit => 100
         t.column :source_id,        :integer,  :limit => 3
         t.column :target_type,      :string,   :limit => 100
         t.column :target_id,        :integer,  :limit => 3
         t.column :message_type,     :string,   :limit => 100
      end
   end

   def self.down
      drop_table :orchestrator_messages
   end
end

## ===================================================================

class CreateMessageParameters < ActiveRecord::Migration[6.0]

   def self.up
      create_table(:message_parameters) do |t|
         t.column :orchestrator_message_id, :integer
         t.column :param_name,              :string,   :limit => 100
         t.column :param_value,             :string,   :limit => 150
      end
      add_foreign_key :message_parameters, :orchestrator_messages
   end

   def self.down
      drop_table :message_parameters
   end
end
## ===================================================================
