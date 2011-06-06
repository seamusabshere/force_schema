# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "create_table/version"

Gem::Specification.new do |s|
  s.name        = "create_table"
  s.version     = CreateTable::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Seamus Abshere"]
  s.email       = ["seamus@abshere.net"]
  s.homepage    = ""
  s.summary     = %q{Force (MySQL) schema changes without caring what happens to the data inside them.}
  s.description = %q{Sometimes you want a table (aka schema) to be just so and you don't care if changing it in-place will delete data (presumably because you can re-create it.)}

  s.rubyforge_project = "create_table"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_development_dependency 'test-unit'
  s.add_development_dependency 'mysql'
  s.add_development_dependency 'ruby-debug19'
  s.add_dependency 'activerecord', '>=3'
  s.add_dependency 'activesupport', '>=3'
  s.add_dependency 'blockenspiel'
end
