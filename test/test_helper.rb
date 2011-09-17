$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'test/unit'
require 'active_record'
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
require File.expand_path('test/tableless')
require File.expand_path('lib/validates_as_email')
