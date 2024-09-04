#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #dropORCTables command
#
# === Written by DEIMOS Space S.L. (rell)
#
# === MDS-LEGOS -> ORC Component
# 
# CVS: $Id: dropORCTables.rb,v 1.6 2008/12/17 17:48:17 decdev Exp $
#
# module ORC
#
#########################################################################

require 'ORC_DataModel'
require 'ORC_Migrations'

puts "START"

if ProductionTimeline.table_exists?() then
   CreateProductionTimelines.down
end

if ObsoleteTriggerProduct.table_exists?() then
   CreateObsoleteTriggerProducts.down
end

if SuccessfulTriggerProduct.table_exists?() then
   CreateSuccessfulTriggerProducts.down
end

if FailingTriggerProduct.table_exists?() then
   CreateFailingTriggerProducts.down
end

if OrchestratorQueue.table_exists?() then
   CreateOrchestratorQueue.down
end

if TriggerProduct.table_exists?() then
   CreateTriggerProducts.down
end

if Pending2QueueFile.table_exists?() then
   CreatePending2QueueFiles.down
end

if MessageParameter.table_exists?() then
   CreateMessageParameters.down
end 

if OrchestratorMessage.table_exists?() then
   CreateOrchestratorMessages.down
end

if RunningJob.table_exists?() then
   CreateRunningJobs.down
end

puts "END"
