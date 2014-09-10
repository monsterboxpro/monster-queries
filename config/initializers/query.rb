require 'query'
ActiveRecord::Base.send(:include, ARQueryExtension)
