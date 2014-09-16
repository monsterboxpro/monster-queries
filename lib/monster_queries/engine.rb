module MonsterQueries
  class Engine < ::Rails::Engine
    initializer 'monster_queries.action_controller' do |app|
      ActionController::Base.send :include, MonsterQueries::Helpers
    end
  end
end
