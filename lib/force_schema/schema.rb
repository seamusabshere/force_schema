require 'blockenspiel'
require 'zlib'
require 'active_support'
require 'active_support/core_ext'
module ForceSchema
  class Schema
    MAX_INDEX_NAME_LENGTH = 32 # mysql
    
    class << self
      def suggest_index_name(active_record, columns, index_options = {})
        return index_options[:name] if index_options.has_key? :name
        default_name = 'index_' + ::Array.wrap(columns).join('_and_') #active_record.connection.index_name(active_record.table_name, index_options.merge(:column => columns))
        if default_name.length < MAX_INDEX_NAME_LENGTH
          default_name
        else
          default_name[0..MAX_INDEX_NAME_LENGTH-11] + ::Zlib.crc32(default_name).to_s
        end
      end
    end
    
    include ::Blockenspiel::DSL

    attr_reader :active_record
    attr_reader :create_table_options

    def initialize(active_record)
      @active_record = active_record
    end
    
    def create_table_options=(options = {})
      @create_table_options = options.symbolize_keys
      raise ":id => true is not allowed in create_table_options." if create_table_options[:id] === true
      raise ":primary_key is not allowed in create_table_options. Use set_primary_key instead." if create_table_options.has_key?(:primary_key)
      if create_table_options[:options].blank? and mysql?
        create_table_options[:options] = 'ENGINE=INNODB CHARSET=UTF8 COLLATE=UTF8_GENERAL_CI'
      end
      create_table_options[:id] = false # always
    end

    # sabshere 1/25/11 lifted straight from activerecord-3.0.3/lib/active_record/connection_adapters/abstract/schema_definitions.rb
    %w( string text integer float decimal datetime timestamp time date binary boolean ).each do |column_type|
      class_eval <<-EOV
        def #{column_type}(*args)                                               # def string(*args)
          options = args.extract_options!                                       #   options = args.extract_options!
          column_names = args                                                   #   column_names = args
                                                                                #
          column_names.each { |name| ideal_table.column(name, '#{column_type}', options) }  #   column_names.each { |name| ideal_table.column(name, 'string', options) }
        end                                                                     # end
      EOV
    end
    
    def index(columns, index_options = {})
      index_options = index_options.symbolize_keys
      columns = ::Array.wrap columns
      index_name = Schema.suggest_index_name active_record, columns, index_options
      index_unique = index_options.has_key?(:unique) ? index_options[:unique] : true
      ideal_indexes.push ::ActiveRecord::ConnectionAdapters::IndexDefinition.new(table_name, index_name, index_unique, columns)
      nil
    end

    def run
      _create_table
      _set_primary_key
      _remove_columns
      _add_columns
      _remove_indexes
      _add_indexes
      nil
    end

    private

    def log_debug(msg)
      ::ActiveRecord::Base.logger.try :debug, msg
    end

    def column(*args)
      ideal_table.column(*args)
    end

    def ideal_primary_key_name
      active_record.primary_key.to_s
    end

    def actual_primary_key_name
      if sqlite? and pk = active_record.columns_hash.detect { |k, v| v.primary }
        pk[1].name
      elsif pk = connection.primary_key(table_name)
        pk
      end.to_s
    end

    def index_equivalent?(a, b)
      return false unless a and b
      %w{ name columns }.all? do |property|
        a_property = ::Array.wrap(a.send(property)).map(&:to_s)
        b_property = ::Array.wrap(b.send(property)).map(&:to_s)
        log_debug "...comparing #{a_property.inspect} <-> #{b_property.inspect}"
        a_property == b_property
      end
    end

    COMPARABLE_OPTIONS = [ :default ] # other things vary rather unpredicatably by adapter
    
    def column_equivalent?(a, b)
      return false unless a and b
      a_type = (a.type.to_s == 'primary_key') ? 'integer' : a.type.to_s
      b_type = (b.type.to_s == 'primary_key') ? 'integer' : b.type.to_s
      a_type == b_type and a.name.to_s == b.name.to_s and column_options(a).slice(COMPARABLE_OPTIONS) == column_options(b).slice(COMPARABLE_OPTIONS)
    end

    %w{ column index }.each do |i|
      eval %{
        def #{i}_needs_to_be_placed?(name)
          actual = actual_#{i} name
          return true unless actual
          ideal = ideal_#{i} name
          not #{i}_equivalent? actual, ideal
        end

        def #{i}_needs_to_be_removed?(name)
          ideal_#{i}(name).nil?
        end
      }
    end

    def ideal_column(name)
      ideal_table[name.to_s]
    end

    def actual_column(name)
      active_record.columns_hash[name.to_s]
    end

    def ideal_index(name)
      ideal_indexes.detect { |ideal| ideal.name == name.to_s }
    end

    def actual_index(name)
      actual_indexes.detect { |actual| actual.name == name.to_s }
    end
    
    POSSIBLE_OPTIONS = [ :limit, :default, :null, :precision, :scale ]
    
    def column_options(column)
      POSSIBLE_OPTIONS.inject({}) do |memo, k|
        v = column.send(k)
        if v == false or v.present?
          memo[k] = v
        end
        memo
      end
    end
    
    def place_column(name)
      remove_column name if actual_column name
      ideal = ideal_column name
      options = column_options ideal
      log_debug "PLACING COLUMN #{name}"
      connection.add_column table_name, name, ideal.type.to_sym, options
      active_record.reset_column_information
    end

    def remove_column(name)
      log_debug "REMOVING COLUMN #{name}"
      connection.remove_column table_name, name
      active_record.reset_column_information
    end

    def place_index(name)
      remove_index name if actual_index name
      ideal = ideal_index name
      log_debug "PLACING INDEX #{name}"
      connection.add_index table_name, ideal.columns, :name => ideal.name
      active_record.reset_column_information
    end

    def remove_index(name)
      log_debug "REMOVING INDEX #{name}"
      connection.remove_index table_name, :name => name
      active_record.reset_column_information
    end

    # sabshere 1/25/11 what if there were multiple connections
    # blockenspiel doesn't like to delegate this to #active_record
    def connection
      ::ActiveRecord::Base.connection
    end

    def table_name
      active_record.table_name
    end

    def ideal_table
      @ideal_table ||= ::ActiveRecord::ConnectionAdapters::TableDefinition.new connection
    end

    def ideal_indexes
      @ideal_indexes ||= []
    end

    def actual_indexes
      connection.indexes table_name
    end

    def _create_table
      if not active_record.table_exists?
        log_debug "CREATING TABLE #{table_name} with #{create_table_options.inspect}"
        connection.create_table table_name, create_table_options do |t|
          t.integer 'force_schema_tmp'
        end
        active_record.reset_column_information
      end
    end

    def _set_primary_key
      if ideal_primary_key_name == 'id' and not ideal_column('id')
        log_debug "no special primary key set on #{table_name}, so using 'id'"
        column 'id', :primary_key # needs to be a sym?
      end
      actual = actual_column actual_primary_key_name
      ideal = ideal_column ideal_primary_key_name
      if not column_equivalent? actual, ideal
        log_debug "looks like #{table_name} has a bad (or missing) primary key"
        if actual
          log_debug "looks like primary key needs to change from #{actual_primary_key_name} to #{ideal_primary_key_name}, re-creating #{table_name} from scratch"
          connection.drop_table table_name
          active_record.reset_column_information
          _create_table
        end
        place_column ideal_primary_key_name
        unless ideal.type.to_s == 'primary_key'
          log_debug "SETTING #{ideal_primary_key_name} AS PRIMARY KEY"
          if sqlite?
            special_sqlite_primary_key_index_name = "IDX_#{table_name}_#{ideal_primary_key_name}"
            connection.execute "CREATE UNIQUE INDEX #{special_sqlite_primary_key_index_name} ON #{table_name} (#{ideal_primary_key_name} ASC)"
            ideal_indexes.push ::ActiveRecord::ConnectionAdapters::IndexDefinition.new(table_name, special_sqlite_primary_key_index_name, true, ideal_primary_key_name)
          else
            connection.execute "ALTER TABLE `#{table_name}` ADD PRIMARY KEY (`#{ideal_primary_key_name}`)"
          end
        end
      end
      active_record.reset_column_information
    end

    def sqlite?
      connection.adapter_name.downcase.start_with? 'sqlite'
    end
    
    def mysql?
      connection.adapter_name.downcase.start_with? 'mysql'
    end

    def _remove_columns
      active_record.columns_hash.values.each do |actual|
        remove_column actual.name if column_needs_to_be_removed? actual.name
      end
    end

    def _add_columns
      ideal_table.columns.each do |ideal|
        place_column ideal.name if column_needs_to_be_placed? ideal.name
      end
    end

    def _remove_indexes
      actual_indexes.each do |actual|
        remove_index actual.name if index_needs_to_be_removed? actual.name
      end
    end

    def _add_indexes
      ideal_indexes.each do |ideal|
        next if ideal.name == ideal_primary_key_name # this should already have been taken care of
        place_index ideal.name if index_needs_to_be_placed? ideal.name
      end
    end
  end
end
