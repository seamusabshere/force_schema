module Shared
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
    assert index?(Car, :index_name_and_make_name)
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
    assert !index?(Car, :index_name_and_make_name)
    Car.create_table!
    assert index?(Car, :index_name_and_make_name)
  end
  
  def test_006_restore_damaged_index
    Car.connection.remove_column :cars, :make_name
    Car.create_table!
    assert index?(Car, :index_name_and_make_name)
  end
  
  def test_007_remove_unrecognized_index
    Car.connection.add_index :cars, :year, :name => 'foobar'
    Car.reset_column_information
    assert index?(Car, :foobar)
    Car.create_table!
    assert !index?(Car, :foobar)
  end
  
  def test_008_primary_key_is_unique
    a = Car.new
    a.name = 'a'
    a.save!
    assert_raises(ActiveRecord::RecordNotUnique) do
      a = Car.new
      a.name = 'a'
      a.save!
    end
  end
  
  def test_009_edge_case_one_column
    ActiveRecord::Base.connection.drop_table 'monks' rescue nil
    Monk.create_table!
    Monk.create_table!
    Monk.create_table!
    assert_equal :string, ct(Monk, :name)
  end
  
  private

  def ct(active_record, column_name)
    if c = active_record.columns_hash[column_name.to_s]
      c.type
    end
  end

  def index?(active_record, index_name)
    active_record.reset_column_information
    index_name = index_name.to_s
    return true if index_name == active_record.primary_key.to_s
    if ActiveRecord::VERSION::MAJOR < 3
      active_record.connection.index_exists?(active_record.table_name, index_name, :not_supported_by_adapter)
    else
      active_record.connection.index_exists?(active_record.table_name, nil, :name => index_name)
    end
  end
end
