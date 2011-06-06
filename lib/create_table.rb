require 'active_record'
require 'active_support/core_ext'

module CreateTable
  autoload :Registry, 'create_table/registry'
  autoload :Schema, 'create_table/schema'
    
  def create_table!
    create_table_schema.run
  end

  def create_table(create_table_options = {}, &blk)
    create_table_schema.create_table_options = create_table_options
    ::Blockenspiel.invoke blk, create_table_schema
    create_table_schema
  end
  
  def create_table_schema
    Registry.instance[name] ||= Schema.new self
  end
end

::ActiveRecord::Base.extend ::CreateTable
