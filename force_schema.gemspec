# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "force_schema/version"

Gem::Specification.new do |s|
  s.name        = "force_schema"
  s.version     = ForceSchema::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Seamus Abshere"]
  s.email       = ["seamus@abshere.net"]
  s.homepage    = "https://github.com/seamusabshere/force_schema"
  s.summary     = %q{Sometimes you don't need to write up and down migrations, you just want a table (aka schema) to have a certain structure.}
  s.description = %q{Declare a table structure like an ActiveRecord migration and run 'force_schema!' whenever you want. For when you don't need up and down migrations.}

  s.rubyforge_project = "force_schema"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_development_dependency 'test-unit'
  s.add_development_dependency 'mysql'
  s.add_development_dependency 'sqlite3-ruby'
  s.add_development_dependency 'rake'
  s.add_dependency 'activerecord', '>=2.3.10'
  s.add_dependency 'activesupport', '>=2.3.10'
  s.add_dependency 'blockenspiel'
end
