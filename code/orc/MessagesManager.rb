#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #GapsExtractor class
#
# === Written by DEIMOS Space S.L. (rell)
#
# === SMOS NRTP Orchestrator
# 
# CVS: $Id: MessagesManager.rb,v 1.2 2008/06/27 14:32:41 decdev Exp $
#
# module ORC
#
#########################################################################

require "cuc/DirUtils"
require "orc/ORC_DataModel"
require "rexml/document"

class MessagesManager

   include CUC::DirUtils
   include REXML

   @arrMessages = Array.new
   @filePath = ""

   #================ Class contructor ================#

   def initialize()
      
   end

   #==================================================#

   def dumpMessagesBySrc(path, src_type, src_id)

      @filePath = path
      
      @arrMessages = OrchestratorMessage.find(:all, :conditions=> "source_type = '#{src_type}' AND source_id = #{src_id}")

      generateListFile

   end
   #-------------------------------------------------------------

   def dumpMessagesByTgt(path, tgt_type, tgt_id)

      @filePath = path
      
      @arrMessages = OrchestratorMessage.find(:all, :conditions=> "target_type = '#{tgt_type}' AND target_id = #{tgt_id}")

      generateListFile

   end
   #-------------------------------------------------------------

   def deleteMessage(dbid)

      begin
         aMes = OrchestratorMessage.find(dbid)
         
         arrParams = MessageParameter.find(:all, :conditions=> "orchestrator_message_id = #{dbid}")

         OrchestratorMessage.transaction do
            arrParams.each{|aParam|
               aParam.destroy
            }
            aMes.destroy
         end

         exit(0)

      rescue
         puts
         puts "Deletion failed for message #{dbid} !"
         puts
         exit(99)
      end
   end 

private

   def generateListFile

      doc = Document.new 
      doc.add_element "MessageList"
      doc << XMLDecl.new

      @arrMessages.each{|aMes|
         
         eMessage = Element.new "Message"
         eMessage.attributes['type'] = aMes.message_type
         eMessage.attributes['id'] = aMes.id.to_s

         eSource = Element.new "Source"
         eSource.attributes['type'] = aMes.source_type
         eSource.attributes['id']   = aMes.source_id.to_s
         eMessage.elements << eSource

         eTarget = Element.new "Target"
         eTarget.attributes['type'] = aMes.target_type
         eTarget.attributes['id']   = aMes.target_id.to_s
         eMessage.elements << eTarget

         eParamList = Element.new "ParamList"
         arrParams = MessageParameter.find(:all, :conditions=> "orchestrator_message_id = '#{aMes.id}'")

         arrParams.each{|aParam|
            eParam = Element.new "Param"
            eParam.attributes['name'] = aParam.param_name
            eParam.text = CData.new(aParam.param_value)
            eParamList.elements << eParam
         }
         eParamList.attributes['cnt'] = arrParams.size.to_s
         eMessage.elements << eParamList

         doc.root.elements << eMessage
      }

      file = File.open(@filePath, "w")
      doc.write(file, 2)
      file.close

   end

end # MessagesManager

