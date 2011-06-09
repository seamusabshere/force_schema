require 'helper'

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'

require 'support/car'
require 'support/monk'

class TestSqlite3 < Test::Unit::TestCase
  include Shared
end
