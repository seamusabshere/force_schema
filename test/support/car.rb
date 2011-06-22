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
    boolean  'consumer_reports_best_buy', :default => false
    index    ['name', 'make_name']
  end
end
