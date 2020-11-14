module MonsterQueries
  class Builder
    def self.with_scope args
      q = self.new nil
      q.scope = args
      q
    end

    attr_writer :scope, :paginate

    def initialize name
      @paginate = false
      @scope = [name]
    end

    def method_missing name, args=nil
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
      MonsterQueries::Query.exists? @scope
    end

    def file_contents variables
      template = MonsterQueries::Query.template @scope
      result = template.call variables
      result
    end
  end # class
end # module
