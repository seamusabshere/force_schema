require 'helper'

class Car < ActiveRecord::Base
  set_primary_key :name
  create_table do
    string   'name'       # Nissan Altima, will automatically be indexed because it's the primary key
    string   'make_name'  # Nissan
    string   'model_name' # Altime
    float    'fuel_efficiency_city'
    string   'fuel_efficiency_city_units'
    float    'fuel_efficiency_highway'
    string   'fuel_efficiency_highway_units'
    integer  'year'
    datetime 'released_at'
    date     'released_on'
    index    ['name', 'make_name']
  end
end

class TestCreateTable < Test::Unit::TestCase
  def setup
    ActiveRecord::Base.connection.drop_table 'cars' rescue nil
    Car.create_table!
  end

  def test_001_add_columns_and_indexes_from_scratch
    assert_equal :string, ct(Car, :name)
    assert_equal :float, ct(Car, :fuel_efficiency_city)
    assert_equal :integer, ct(Car, :year)
    assert_equal :datetime, ct(Car, :released_at)
    assert_equal :date, ct(Car, :released_on)
    assert index?(Car, [:name, :make_name])
  end
  
  def test_002_restore_removed_column
    Car.connection.remove_column :cars, :year
    assert_equal nil, ct(Car, :year)
    Car.create_table!
    assert_equal :integer, ct(Car, :year)
  end
  
  def test_003_fix_column_type
    Car.connection.remove_column :cars, :year
    Car.connection.add_column :cars, :year, :string
    Car.reset_column_information
    assert_equal :string, ct(Car, :year)
    Car.create_table!
    assert_equal :integer, ct(Car, :year)
  end
  
  def test_004_remove_unrecognized_column
    Car.connection.add_column :cars, :foobar, :string
    assert_equal :string, ct(Car, :foobar)
    Car.create_table!
    assert_equal nil, ct(Car, :foobar)
  end
  
  def test_005_restore_removed_index
    Car.connection.remove_index :cars, :name => 'index_name_and_make_name'
    Car.reset_column_information
    assert !Car.connection.index_exists?(:cars, [:make, :make_name], :name => 'index_name_and_make_name')
    Car.create_table!
    assert Car.connection.index_exists?(:cars, [:make, :make_name], :name => 'index_name_and_make_name')
  end
  
  def test_006_restore_damaged_index
    Car.connection.remove_column :cars, :make_name
    Car.create_table!
    assert index?(Car, [:name, :make_name])
  end
  
  def test_007_remove_unrecognized_index
    Car.connection.add_index :cars, :year, :name => 'foobar'
    Car.reset_column_information
    assert Car.connection.index_exists?(:cars, :year, :name => 'foobar')
    Car.create_table!
    assert !Car.connection.index_exists?(:cars, :year, :name => 'foobar')
  end
  
  private

  def ct(active_record, c_name)
    if c = active_record.columns_hash[c_name.to_s]
      c.type
    end
  end

  def index?(active_record, columns, index_options = {})
    return true if columns.to_s == active_record.primary_key.to_s
    i_name = CreateTable::Schema.suggest_index_name(active_record, columns, index_options)
    active_record.connection.index_exists?(active_record.table_name, columns, :name => i_name)
  end
end
