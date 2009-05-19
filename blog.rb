require 'rubygems'
require 'activesupport'

require 'stone'

require 'sinatra'
require 'redcloth'
require 'models/post'

ROOT = File.expand_path(File.join(File.dirname(__FILE__))) unless Object.const_defined?(:ROOT)
STYLESHEETS_ROOT = File.join(ROOT, 'sass') unless Object.const_defined?(:SASS_ROOT)
TEMPLATES_ROOT = File.join(ROOT, 'templates') unless Object.const_defined?(:TEMPLATES_ROOT)
LAYOUTS_ROOT = File.join(ROOT, 'layouts') unless Object.const_defined?(:LAYOUTS_ROOT)

module EngineFactory
    # @cache = Cache.new
  class << self
    def load(filename)
      source = File.open(filename, 'r').read
      case extension = File.extname(filename)[1..-1]
        when 'haml' then Haml::Engine.new(source)
        when 'sass' then Sass::Engine.new(source, :load_paths => [STYLESHEETS_ROOT], :style => ENV['RACK_ENV'] == 'development' ? :expanded : :compressed)
        when 'builder' then Stone::BuilderEngine.new(source, :indent => 2)
        else raise 'unknown engine extension: #{extension}'
      end
    end
    
      # process_method = instance_method(:load)
      # define_method :load do |*args|
      #   @cache.read(args) do 
      #     process_method.bind(self).call(*args)
      #   end
      # end
  end
end

class EngineHouse
  def initialize(root, &block)
    @root = root
    @cache = {}
    @block = block || proc {|engine| engine}
    self.reload!
  end

  def reload!
    @cache = {}
  end

  def [](filename)
    filename = File.join(@root, filename)
    @cache[filename] ||= @block.call(EngineFactory.load(filename))
  end
end

Templates = EngineHouse.new(TEMPLATES_ROOT) {|engine| Stone::Template.new(engine)}
Layouts = EngineHouse.new(LAYOUTS_ROOT) {|engine| Stone::Layout.new(engine)}
Stylesheets = EngineHouse.new(STYLESHEETS_ROOT)

module Helpers
  def ordinalize(number)
    if (11..13).include?(number.to_i % 100)
      "#{number}th"
    else
      case number.to_i % 10
        when 1 then "#{number}st"
        when 2 then "#{number}nd"
        when 3 then "#{number}rd"
        else "#{number}th"
      end
    end
  end

  def template(filename, locals = {})
    Templates[filename].render(self.locals.merge(locals), self.globals, self.bound_content)
  end

  def escape(s)
    s.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/n) {
      '%'+$1.unpack('H2'*$1.size).join('%').upcase
    }.tr(' ', '+')
  end
end

class Stone::Renderer
  include(Helpers)
end

before do
  unless ENV['RACK_ENV'] == 'production'
    Templates.reload!
    Layouts.reload!
    Stylesheets.reload!
    Post.reload!
  end
end

helpers do
  def render(filename, locals = {}, options = {:layout => true})
    locals = locals.reverse_merge(:request => request)
    options[:layout] ? Layouts['application.haml'].render(Templates[filename], locals) : Templates[filename].render(locals)
  end
end

get '/' do
  render('index.haml', :title => 'Home', :posts => Post.all)
end

get '/post/:permalink' do
  pass unless post = Post.all_by_permalink[params[:permalink]]
  render('show.haml', :title => post.title, :post => post)
end

get '/posts/:month' do
  pass unless posts = Post.all_by_date[params[:month]]
  render('index.haml', :title => params[:month], :posts => posts)
end

get '/posts/:category' do
  pass unless posts = Post.all_by_category[params[:category]]
  render('index.haml', :title => params[:category], :posts => posts)
end

get '/posts.rss' do                                                                                  
  content_type 'application/rss+xml', :charset => 'utf-8'
  render('index.builder', {:posts => Post.all}, :layout => false)
end

get '/stylesheets/application.css' do
  content_type 'text/css', :charset => 'utf-8'
  Stylesheets['application.sass'].render
end