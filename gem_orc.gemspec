require_relative 'code/orc/ORC_Environment'
include ORC

Gem::Specification.new do |s|
  s.name        = 'orc'
  s.version     = "#{ORC::VERSION}"
  s.licenses    = ['MIT']
  s.summary     = "DEC/ORC component"
  s.description = "Generic Orchestrator"
  s.authors     = ["Elecnor Deimos"]
  s.email       = 'borja.lopez.fernandez@gmail.com'
  
  s.required_ruby_version = '>= 2.7'
  
  s.files       = Dir['code/orc/*.rb'] + \
                  Dir['code/orc/orcIngester'] + \
                  Dir['code/orc/orcUnitTests'] + \
                  Dir['code/cuc/*.rb'] + \
                  Dir['schemas/common_types.xsd'] + \
                  Dir['schemas/orchestrator_log_config.xsd'] + \
                  Dir['schemas/orchestratorConfigFile.xsd'] + \
                  Dir['config/orchestratorConfigFile.xml'] + \
                  Dir['config/orchestrator_log_config.xml'] + \
                  Dir['config/orc_test.env'] + \
                  Dir['config/orc_test_postgresql.env'] + \
                  Dir['install/orc_test.bash']

  s.require_paths = ['code', 'code/orc']

  s.bindir        = ['code/orc']

  s.executables   = [ 
                     'orcBolg', \
                     'orcIngester', \
                     'orc_eboa_triggering', \
                     'orcManageDB', \
                     'orcQueueInput', \
                     'orcQueueUpdate', \
                     'orcResourceChecker', \
                     'orcScheduler', \
                     'orcUnitTests', \
                     'orcUnitTests_NAOS', \
                     'orcUnitTests_BOA', \
                     'orcValidateConfig'
                     ]

  s.homepage    = 'https://github.com/mansobeach/orc'
  
  s.metadata    = { "source_code_uri" => "https://github.com/mansobeach/orc" }
  

  ## ----------------------------------------------
  
  ### PENDING COMPLETION OF MINARC 1.1.0
  ### s.add_dependency('minarc', '> 1.0.34')

  s.add_dependency('dotenv', '~> 3.1')
  s.add_dependency('activerecord-import', '~> 1.0')
  s.add_dependency('log4r', '~> 1.0')  
  s.add_dependency('pg', '~> 1.2.3')
  ## ----------------------------------------------
  
  s.add_development_dependency('sqlite3', '~> 1.4')
  s.add_development_dependency('test-unit', '~> 3.0')
  
  ## ----------------------------------------------  
    
  s.post_install_message = "#{'1F4E1'.hex.chr('UTF-8')} ORC #{'1F47E'.hex.chr('UTF-8')} Orchestrator installed #{ORC::VERSION} \360\237\215\200 \360\237\215\200 \360\237\215\200"
  
end
