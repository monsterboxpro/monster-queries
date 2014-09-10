require 'handlebars'
class Q
  @template_cache = {}
  @exists_cache = {}
  SKIP_CACHE = (Rails.env == 'development')

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
      @handlebars = Handlebars::Context.new
      @handlebars.register_helper(:include) do |context,name,options|
        variables = {}
        context.each do |k,v|
          variables[k] = v
        end
        options['hash'].each do |k,v|
          variables[k] = v
        end
        parts = name.split('.')
        QueryBuilder.with_scope(parts).to_s variables
      end
      @handlebars.register_helper(:wildcard) do |context,value,options|
        ActiveRecord::Base.connection.quote "%#{value}%"
      end
      @handlebars.register_helper(:quote) do |context,value,options|
        ActiveRecord::Base.connection.quote value
      end
      @handlebars.register_helper(:int) do |context,value,options|
        value.to_i
      end
      @handlebars.register_helper(:float) do |context,value,options|
        value.to_f
      end
    end
    @handlebars
  end

  def self.template file_name
    if !@template_cache[file_name] || SKIP_CACHE
      data = File.read file_name
      @template_cache[file_name] = Q.handlebars.compile(data, noEscape: true)
    end
    @template_cache[file_name]
  end

  def self.exists? file_name
    if !@exists_cache[file_name] || SKIP_CACHE
      @exists_cache[file_name] = File.file?(file_name)
    end
    @exists_cache[file_name]
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
    @file_name = nil
    file_exists? ? file_contents(args) : self
  end

  def to_s args={}
    if file_exists?
      file_contents args
    else
      raise "Query doesn't exist: #{@scope.join('/')}"
    end
  end

  def paginate
    @paginate = true
    self
  end

  private

  def file_exists?
    Q.exists? file_name
  end

  def file_name
    unless @file_name
      scope = @scope[0...-1]
      scope << @scope.last.to_s + ".sql"
      @file_name = Rails.root.join('app','queries',*scope.compact.map(&:to_s))
    end
    @file_name
  end

  def file_contents variables
    if @paginate
      template = Q.template(Rails.root.join('app','queries','shared','paginate.sql'))
      variables[:template_name] = @scope.compact.join('.')
      variables[:per_page] = 20
    else
      template = Q.template(file_name)
    end
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

  def select_array query
    select_value(query) || '[]'
  end

  def select_object query
    select_value(query) || '{}'
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

    def select_array query
      select_value(query) || '[]'
    end

    def select_object query
      select_value(query) || '{}'
    end
  end
end
