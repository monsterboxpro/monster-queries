module MonsterQueries
  module ActiveRecord
    extend ActiveSupport::Concern

    def execute query
      begin
        self.class.connection.execute query
      rescue
        File.open(Rails.root.join('tmp','failed.sql'), 'w') { |file| file.write(query) }
        Rails.root.join
        raise
      end
    end

    def select_value query
      begin
        self.class.connection.select_value query
      rescue
        File.open(Rails.root.join('tmp','failed.sql'), 'w') { |file| file.write(query) }
        raise
      end
    end

    def select_values query
      begin
        self.class.connection.select_values query
      rescue
        File.open(Rails.root.join('tmp','failed.sql'), 'w') { |file| file.write(query) }
        raise
      end
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
  end # module
end # module
