# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "create_table/version"

Gem::Specification.new do |s|
  s.name        = "create_table"
  s.version     = CreateTable::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Seamus Abshere"]
  s.email       = ["seamus@abshere.net"]
  s.homepage    = "https://github.com/seamusabshere/create_table"
  s.summary     = %q{Sometimes you don't need to write up and down migrations, you just want a table (aka schema) to have a certain structure.}
  s.description = %q{Declare a table structure like an ActiveRecord migration and run 'create_table!' whenever you want. For when you don't need up and down migrations.}

  s.rubyforge_project = "create_table"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_development_dependency 'test-unit'
  s.add_development_dependency 'mysql'
  s.add_dependency 'activerecord', '>=3'
  s.add_dependency 'activesupport', '>=3'
  s.add_dependency 'blockenspiel'
end
