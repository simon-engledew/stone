require 'stone'
require 'sinatra'
require 'redcloth'
require 'activesupport'

class Post
  def initialize(filename)
    @permalink = File.basename(filename, File.extname(filename))
    
    match = File.open(filename, 'r').read.match(/(.*?)^$(.*)/m)
    
    attributes = YAML.load(match[1])

    @content = match[2]
    @category = attributes['category']
    @published = attributes['published']
    @created_at = DateTime.parse(attributes['created_at'])
    @title = attributes['title']
  end
  
  class << self
    def all
      @cache[:all] ||= Dir.glob(File.join(ROOT, 'posts', '*')).map{|filename|Post.new(filename)}.sort_by{|post|post.created_at}.reverse
    end
  
    def all_by_date
      @cache[:all_by_date] ||= ActiveSupport::OrderedHash.new.tap do |all_by_date|
        Post.all.each do |post|
          month = post.created_at.strftime('%B %Y')
          all_by_date[month] ||= []
          all_by_date[month] << post
        end
      end
    end
  
    def all_by_permalink
      @cache[:all_by_permalink] ||= ActiveSupport::OrderedHash.new.tap do |hash|
        Post.all.each {|post| hash[post.permalink] = post}
      end
    end
    
    def all_by_category
      @cache[:all_by_category] ||= ActiveSupport::OrderedHash.new.tap do |hash|
        Post.all.each do |post|
          hash[post.category] ||= []
          hash[post.category] << post
        end
      end
    end
    
    def reload!
      @cache = {}
    end
  end
  
  Post.reload!
  
  attr_reader :content, :published, :created_at, :title, :permalink, :category
end

before do
  if ENV['RACK_ENV'] == 'development'
    Templates.reload!
    Layouts.reload!
    Stylesheets.reload!
    Post.reload!
  end
end

helpers do
  def render(filename, locals = {}, options = {:layout => true})
    locals = locals.merge(:request => request)
    options[:layout] ? Layouts['application.haml'].render(Templates[filename], locals) : Templates[filename].render(locals)
  end
end

application_layout = Layouts['application.haml']

get '/' do
  render('index.haml', :title => 'Home', :posts => Post.all)
end

get '/post/:permalink' do
  pass unless post = Post.all_by_permalink[params[:permalink]]
  render('show.haml', :title => post.title, :post => post)
end

get '/posts.rss' do                                                                                  
  content_type 'application/rss+xml', :charset => 'utf-8'
  render('index.builder', {:posts => Post.all}, :layout => false)
end

get '/posts/:month' do
  pass unless posts = Post.all_by_date[params[:month]]
  render('index.haml', :title => params[:month], :posts => posts)
end

get '/posts/:category' do
  pass unless posts = Post.all_by_category[params[:category]]
  render('index.haml', :title => params[:category], :posts => posts)
end

get '/stylesheets/application.css' do
  content_type 'text/css', :charset => 'utf-8'
  Stylesheets['application.sass'].render
end