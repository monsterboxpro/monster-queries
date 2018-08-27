require 'monster_queries/query'
ActiveRecord::Base.send     :include, MonsterQueries::ActiveRecord
ActionController::Base.send :include, MonsterQueries::ActionController
Q = MonsterQueries::Query
