require 'handlebars'
class Q
  @template_cache = {}
  @exists_cache = {}
  SKIP_CACHE = true

  def self.method_missing name
    QueryBuilder.new name
  end

  def self.paginate
    q = QueryBuilder.new nil
    q.paginate = true
    q
  end

  def self.handlebars
    unless @handlebars
      include_helper = ->(context,name,options) {
        variables = {}
        context.each do |k,v|
          variables[k] = v
        end
        options['hash'].each do |k,v|
          variables[k] = v
        end if options
        parts = name.split('.')
        QueryBuilder.with_scope(parts).to_s variables
      }
      @handlebars = Handlebars::Context.new
      @handlebars.register_helper(:include,&include_helper)
      @handlebars.register_helper(:paginate) do |context,value,options|
        if value.is_a?(String)
          count = context.detect{|k,v| k == 'count'}
          if !count.nil? && count[1] == true
            include_helper.call(context,'pagination.select',options)
          else
            include_helper.call(context,value,options)
          end
        else
          content = value.fn(context)
        end
      end
      @handlebars.register_helper(:paginate_offset) do |context,value,options|
        include_helper.call(context,'pagination.offset',options)
      end
      @handlebars.register_helper(:wildcard) do |context,value,options|
        ActiveRecord::Base.connection.quote "%#{value.gsub('\\','\\\\\\')}%"
      end
      @handlebars.register_helper(:quote) do |context,value,options|
        if value.is_a?(V8::Array)
          value.collect{|v| ActiveRecord::Base.connection.quote v}.join(',')
        else
          ActiveRecord::Base.connection.quote value
        end
      end
      @handlebars.register_helper(:int) do |context,value,options|
        value.to_i
      end
      @handlebars.register_helper(:float) do |context,value,options|
        value.to_f
      end
      @handlebars.register_helper(:array) do |context,block,options|
        if block.is_a?(String)
          content = "\n" + include_helper.call(context,block,options)
        else
          content = block.fn(context)
        end
        r = "(SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM ("
        r << content
        r << ") array_row)"
        r
      end
      @handlebars.register_helper(:object) do |context,block,options|
        if block.is_a?(String)
          content = "\n" + include_helper.call(context,block,options)
        else
          content = block.fn(context)
        end
        r = "(SELECT COALESCE(row_to_json(object_row),'{}'::json) FROM ("
        r << content
        r << ") object_row)"
        r
      end
    end
    @handlebars
  end

  def self.locate_file scope
    search_paths = [Rails.root,MonsterQueries::Engine.root]
    search_paths.each do |path|
      file = path.join('app','queries',*scope.compact.map(&:to_s)).to_s + '.sql'
      return file if File.exists?(file)
    end
    return false
  end

  def self.template scope
    if !@template_cache[scope.join('.')] || SKIP_CACHE
      file_name = locate_file(scope)
      data = File.read file_name
      @template_cache[scope.join('.')] = Q.handlebars.compile(data, noEscape: true)
    end
    @template_cache[scope.join('.')]
  end

  def self.exists? scope
    if !@exists_cache[scope] || SKIP_CACHE
      file_name = locate_file(scope)
      @exists_cache[scope] = file_name && File.file?(file_name)
    end
    @exists_cache[scope]
  end
end

class QueryBuilder
  def self.with_scope args
    q = QueryBuilder.new nil
    q.scope = args
    q
  end

  attr_writer :scope, :paginate

  def initialize name
    @paginate = false
    @scope = [name]
  end

  def method_missing name, args={}
    @scope << name
    file_exists? ? file_contents(args) : self
  end

  def to_s args={}
    if file_exists?
      ::Rails.logger.tagged('MONSTER QUERY') do
        ::Rails.logger.info {"Rendered #{@scope.join('.')}"}
      end
      file_contents args
    else
      raise "Query doesn't exist: #{@scope.join('.')}"
    end
  end

  def paginate
    @paginate = true
    self
  end

  private

  def file_exists?
    Q.exists? @scope
  end

  def file_contents variables
    template = Q.template(@scope)
    result = template.call variables
    result
  end
end

module ARQueryExtension
  extend ActiveSupport::Concern

  def execute query
    self.class.connection.execute query
  end

  def select_value query
    self.class.connection.select_value query
  end

  def select_values query
    self.class.connection.select_values query
  end

  def select_json query, count
    if count
      select_object query
    else
      select_array query
    end
  end

  def select_array query
    sql = <<-SQL
      SELECT COALESCE(array_to_json(array_agg(row_to_json(query_row))), '[]'::json)
      FROM (#{query}) query_row
    SQL
    select_value sql
  end

  def select_object query
    sql = <<-SQL
      SELECT COALESCE(row_to_json(query_row),'{}'::json)
      FROM (#{query}) query_row
    SQL
    select_value sql
  end


  def select_all query
    self.class.connection.select_all query
  end


  module ClassMethods
    def execute query
      connection.execute query
    end

    def select_value query
      connection.select_value query
    end

    def select_values query
      connection.select_values query
    end

    def select_json query, count
      if count
        select_object query
      else
        select_array query
      end
    end

    def select_array query
      sql = <<-SQL
        SELECT COALESCE(array_to_json(array_agg(row_to_json(query_row))), '[]'::json)
        FROM (#{query}) query_row
      SQL
      select_value sql
    end

    def select_object query
      sql = <<-SQL
        SELECT COALESCE(row_to_json(query_row),'{}'::json)
        FROM (#{query}) query_row
      SQL
      select_value sql
    end
  end
end
