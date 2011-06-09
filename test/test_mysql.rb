require 'helper'

ActiveRecord::Base.establish_connection(
  'adapter' => 'mysql',
  'database' => 'test_create_table',
  'username' => 'root',
  'password' => 'password',
  'encoding' => 'utf8'
)

require 'support/car'
require 'support/monk'

class TestMysql < Test::Unit::TestCase
  include Shared
end
