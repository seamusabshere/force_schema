require 'rubygems'
require 'bundler'
Bundler.setup
require 'logger'
require 'test/unit'
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'create_table'
class Test::Unit::TestCase
end

ActiveRecord::Base.logger = Logger.new($stderr)

ActiveRecord::Base.establish_connection(
  'adapter' => 'mysql',
  'database' => 'test_create_table',
  'username' => 'root',
  'password' => 'password'
)
