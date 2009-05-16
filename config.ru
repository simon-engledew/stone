require 'rubygems'
require 'sinatra'

disable :run

require 'blog'
run Sinatra::Application
