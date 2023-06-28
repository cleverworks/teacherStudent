#!/usr/bin/env ruby

require 'sinatra'
require 'mongoid'
require 'pry'
require "httpx"

# CORS handler
require "sinatra/cors"

# Include all the models
Dir["./models/*.rb"].each {|file| require file }

# Include all the routes
Dir["./routes/*.rb"].each {|file| require file }

set :allow_origin, "*"
set :allow_methods, "GET,HEAD,POST,PUT,DELETE,OPTIONS"
set :allow_headers, "content-type,if-modified-since"
set :expose_headers, "location,link"
# Development
# set :bind, '0.0.0.0'

before do
  content_type :json
end

Mongoid.load!(File.join(File.dirname(__FILE__), 'config', 'mongoid.yml'))
