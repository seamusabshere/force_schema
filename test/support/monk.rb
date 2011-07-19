class Monk < ActiveRecord::Base
  set_primary_key :name

  force_schema do
    string   'name'
  end
end
