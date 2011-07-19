require 'active_record'
require 'active_support/core_ext'

module ForceSchema
  autoload :Registry, 'force_schema/registry'
  autoload :Schema, 'force_schema/schema'
    
  def force_schema!
    enforced_schema.run
  end

  def force_schema(create_table_options = {}, &blk)
    enforced_schema.create_table_options = create_table_options
    ::Blockenspiel.invoke blk, enforced_schema
    enforced_schema
  end
  
  def enforced_schema
    Registry.instance[name] ||= Schema.new self
  end
end

::ActiveRecord::Base.extend ::ForceSchema
