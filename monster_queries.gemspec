$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "monster_queries/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "monster-queries"
  s.version     = MonsterQueries::VERSION
  s.authors     = ["Monsterbox Productions"]
  s.email       = ["andrew@monsterboxpro.com"]
  s.homepage    = "http://monsterboxpro.com"
  s.summary     = 'Queries'
  s.description = 'Queries'
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 4.2.3"
  s.add_dependency 'handlebars'
  s.add_dependency 'libv8'

  s.add_development_dependency "sqlite3"
end
