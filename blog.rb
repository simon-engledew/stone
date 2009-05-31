require 'rubygems'
require 'activesupport'

require 'stone'

require 'sinatra'
require 'redcloth'
require 'helpers/application'
require 'models/application'
require 'models/post'

ROOT = File.expand_path(File.join(File.dirname(__FILE__))) unless Object.const_defined?(:ROOT)

Templates = EngineHouse.new(File.join(ROOT, 'templates')) {|engine| Stone::Template.new(engine)}
Layouts = EngineHouse.new(File.join(ROOT, 'layouts')) {|engine| Stone::Layout.new(engine)}
Stylesheets = EngineHouse.new(File.join(ROOT, 'sass'))

module TemplateHelper
  def template(filename, locals = {})
    Templates[filename].render(self.locals.merge(locals), self.globals, self.bound_content)
  end
end

module LinkHelper
  def root_url
    return root_url ||= "#{@request.scheme}://#{@request.host}" + if (@request.scheme == 'https' and @request.port != 443) || (@request.scheme == 'http' and @request.port != 80)
      ":#{@request.port}"
    end.to_s
  end
end

class Stone::Renderer
  include(TemplateHelper)
  include(LinkHelper)
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
  def render(filename, locals = {})
    Layouts['application.haml'].render(Templates[filename], locals.reverse_merge(:request => request))
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
  Templates['index.builder'].render(:posts => Post.all)
end

get '/stylesheets/application.css' do
  content_type 'text/css', :charset => 'utf-8'
  Stylesheets['application.sass'].render
end