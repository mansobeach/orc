#!/usr/bin/env ruby

#########################################################################
##
## === Ruby source for #DEC repository management
##
## === Written by DEIMOS Space S.L. (bolf)
##
## === Data Exchange Component (DEC) repository
## 
## Git: rakefile,v $Id$ $Date$
##
## module DEC
##
#########################################################################

require 'rake'


## =============================================================================
##
## Task associated to ORC component

namespace :orc do

   ## -----------------------------
   ## Orchestrator Config files
   
   @arrConfigFiles = [\
      "orchestratorConfigFile.xml",\
      "orchestrator_log_config.xml"]
   ## -----------------------------


   @rootConf = "config/oper_orc"

   ## ----------------------------------------------------------------
   
   desc "build orc gem"

   task :build, [:user, :host] => :load_config do |t, args|
      args.with_defaults(:user => :orctest, :host => "localhost")
      puts "building gem orchestrator with config #{args[:user]}@#{args[:host]}"
   
      if File.exist?("#{@rootConf}/#{args[:user]}@#{args[:host]}") == false then
         puts "Orchestrator configuration not present in repository"
         exit(99)
      end
   
      cmd = "gem build gem_orc.gemspec"
      puts cmd
      ret = `#{cmd}`
      if $? != 0 then
         puts "Failed to build gem for Orchestrator"
         exit(99)
      end

      begin
         File.unlink("install/gems/orc_latest.gem.md5")
      rescue Exception => e
         # puts e.to_s
      end

      filename = ret.split("File: ")[1].chop
      name     = File.basename(filename, ".*")
      cp filename, "orc_latest.gem"
      mv "orc_latest.gem", "install"
      mv filename, "#{name}_#{args[:user]}@#{args[:host]}.gem"
      @filename = "#{name}_#{args[:user]}@#{args[:host]}.gem"
      # mv filename, "install/gems"
      cp @filename, "install/gems/"

      cmd = "md5sum #{@filename}"
      puts cmd
      ret = `#{cmd}`
      cmd = "echo #{ret.split(" ")[0]} > #{@filename}.md5"
      puts cmd
      system(cmd)

      ln "#{@filename}.md5", "install/gems/orc_latest.gem.md5"

   end

   ## ----------------------------------------------------------------

   desc "list Orchestrator configuration packages"

   task :list_config do
      cmd = "ls #{@rootConf}"
      system(cmd)
   end

   ## ----------------------------------------------------------------

   desc "load Orchestrator configuration package"

   task :load_config, [:user, :host] do |t, args|
      args.with_defaults(:user => :orctest, :host => "localhost")
      puts "loading configuration for #{args[:user]}@#{args[:host]}"      
      path     = "#{@rootConf}/#{args[:user]}@#{args[:host]}"
      
      if File.exist?(path) == false then
         mkdir_p path
      end
      
      prefix   = "#{args[:user]}@#{args[:host]}#"
      
      @arrConfigFiles.each{|file|
         filename = "#{path}/#{prefix}#{file}"
         cp filename, "config/#{file}"
      }
   end
   ## --------------------------------------------------------------------

   desc "save Orchestrator configuration package"

   task :save_config, [:user, :host] do |t, args|
      args.with_defaults(:user => :orctest, :host => :localhost)
            
      path     = "#{@rootConf}/#{args[:user]}@#{args[:host]}"
      
      if File.exist?(path) == false then
         mkdir_p path
      else
         puts
         puts "THINK CAREFULLY !"
         puts
         puts "this will overwrite configuration for #{args[:user]}@#{args[:host]}"
         puts
         puts "proceed? Y/n"
               
         c = STDIN.getc   
         if c != 'Y' then
            exit(99)
         end
      end
      
      prefix   = "#{args[:user]}@#{args[:host]}#"
      
      @arrConfigFiles.each{|file|
         cp "config/#{file}", filename = "#{path}/#{prefix}#{file}"
      }
   end
   ## --------------------------------------------------------------------

   task :install ,[:user, :host] => :build do |t, args|
      args.with_defaults(:user => :orctest, :host => :localhost)
      puts
      puts @filename
      puts
      cmd = "gem uninstall -x orc"
      puts cmd
      system(cmd)
      cmd = "gem install #{@filename}"
      puts cmd
      system(cmd)
   end
   ## --------------------------------------------------------------------

   ## Use this task to maintain an index of the relevant configurations
   ##
   desc "help in the kitchen"

   task :help do
      puts "The kitchen supports the following parameters"
      puts "user => used to define the node" 
      puts "host => used to define the node"
      puts
      puts
      puts "Most used recipes:" 
      puts
      puts " *** ORC unit tests ***"
      puts "rake -f build_minarc.rake minarc:install[orctest,localhost]"
      puts "rake -f build_orc.rake orc:install[orctest,localhost]"
      puts
      puts " *** BOA ***"
      puts "rake -f build_minarc.rake minarc:install[naosboa,orc_boa,naos_test_pg]"
      puts "rake -f build_orc.rake orc:install[boatest,orc_boa]"
      puts
      puts " *** NAOSBOA ***"
      puts "rake -f build_minarc.rake minarc:install[naosboa,orc_boa,naos_test_pg]"
      puts "rake -f build_orc.rake orc:install[naosboa,orc_boa]"
      puts
      puts " *** S2PDGSENG / Inputhub ***"
      puts "rake -f build_minarc.rake minarc:build[boa_app_s2boa,e2espm-inputhub,s2_pg]"
      puts "rake -f build_orc.rake orc:build[boa_app_s2boa,e2espm-inputhub]"
      puts
      puts "*** CloudFerro / S2BOA ***"
      puts "rake -f build_orc.rake orc:build[boa_app_s2boa,e2espm-inputhub]"
      puts "rake -f build_orc.rake orc:build[s1boa,cloud_sboa]"
      puts
   end
   ## --------------------------------------------------------------------

   ## --------------------------------------------------------------------

end


## ==============================================================================

task :default do
   puts "DEC / ORC repository management"
   cmd = "rake -f build_orc.rake -T"
   system(cmd)
end

## ==============================================================================

