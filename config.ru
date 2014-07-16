# Gemfile
require "rubygems"
require "bundler/setup"

require "sinatra"
require "haml"
require_relative "app/planetext"
 
set :run, false
set :raise_errors, true
 
run PlaneText
