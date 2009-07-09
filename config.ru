require 'rubygems'

# gem 'sinatra-sinatra'
require 'sinatra'

disable :run

require 'blog'
run Sinatra::Application
