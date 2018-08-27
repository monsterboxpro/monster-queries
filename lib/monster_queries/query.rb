require 'active_record'
require 'handlebars'
require 'pry'
module MonsterQueries
  class Query
    @template_cache = {}
    @exists_cache = {}
    SKIP_CACHE = true

    def self.template_from_parts parts, vars
      MonsterQueries::Builder.with_scope(parts).to_s vars
    end

    # Method Missing is used to create a chain path
    # to the query eg. Q.admin.users.index
    def self.method_missing name
      MonsterQueries::Builder.new name
    end

    def self.paginate
      q = MonsterQueries::Builder.new nil
      q.paginate = true
      q
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
        @template_cache[scope.join('.')] = handlebars.compile(data, noEscape: true)
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

    def self.handlebars
      return @handlebars if @handlebars
      @handlebars = Handlebars::Context.new
      @handlebars.register_helper :include        , &(method(:helper_include).to_proc)
      @handlebars.register_helper :paginate       , &(method(:helper_paginate).to_proc)
      @handlebars.register_helper :paginate_offset, &(method(:helper_paginate_offset).to_proc)
      @handlebars.register_helper :wildcard       , &(method(:helper_wildcard).to_proc)
      @handlebars.register_helper :quote          , &(method(:helper_quote).to_proc)
      @handlebars.register_helper :int            , &(method(:helper_int).to_proc)
      @handlebars.register_helper :float          , &(method(:helper_float).to_proc)
      @handlebars.register_helper :array          , &(method(:helper_array).to_proc)
      @handlebars.register_helper :object         , &(method(:helper_object).to_proc)
      @handlebars
    end

    def self.helper_include context, name, options
      vars = {}
      context.each do |k,v|
        vars[k] = v
      end
      options['hash'].each do |k,v|
        vars[k] = v
      end if options
      parts = name.split('.')
      MonsterQueries::Builder.with_scope(parts).to_s vars
    end

    def self.helper_paginate context, value, options
      if value.is_a?(String)
        count = context.detect{|k,v| k == 'count'}
        name = !count.nil? && count[1] == true ? 'pagination.select' : value
        helper_include.call context, name, options
      else
        value.fn context
      end
    end

    def self.helper_paginate_offset context, value, options
      helper_include.call context, 'pagination.offset', options
    end

    def self.helper_wildcard context, value, options
      ::ActiveRecord::Base.connection.quote "%#{value.gsub('\\','\\\\\\')}%"
    end

    def self.helper_quote context, value, options
      if value.is_a?(V8::Array)
        value.collect{|v| ::ActiveRecord::Base.connection.quote v}.join(',')
      else
        ::ActiveRecord::Base.connection.quote value
      end
    end

    def self.helper_int context, value, options
      value.to_i
    end

    def self.helper_float context, value, options
      value.to_f
    end

    def self.helper_array context, block, options
      content =
      if block.is_a?(String)
        "\n" + helper_include(context, block, options)
      else
        block.fn context
      end
      <<-HEREDOC
(SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
#{content}
array_row)
      HEREDOC
    end

    def self.helper_object context, block, options
      content =
      if block.is_a?(String)
        "\n" + helper_include(context, block, options)
      else
        block.fn context
      end
      <<-HEREDOC
(SELECT COALESCE(row_to_json(object_row),'{}'::json) FROM (
#{content}
) object_row)
      HEREDOC
    end
  end # class
end # module
