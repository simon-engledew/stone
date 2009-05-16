require 'stone'
require 'sinatra'
require 'redcloth'
require 'activesupport'

class Local < Hash
  def method_missing(method, *args)
    self[method.to_s] || super
  end
end

def permalink(filename)
  File.basename(filename, File.extname(filename))
end

ordered_posts = Dir.glob(File.join(ROOT, 'posts', '*')).map do |post|
  if match = File.open(post, 'r').read.match(/(.*?)^$(.*)/m)
    local = Local.new
    local.merge!(YAML.load(match[1]))
    local.merge!('content' => match[2], 'permalink' => permalink(post))
    local['created_at'] = DateTime.parse(local['created_at'])
    local
  else
    raise "could not parse #{post}"
  end
end.sort_by{|post|post.created_at}.reverse

posts_by_permalink = ActiveSupport::OrderedHash.new.tap do |posts_by_permalink|
  ordered_posts.each {|post| posts_by_permalink[post.permalink] = post}
end

posts_by_date = ActiveSupport::OrderedHash.new.tap do |posts_by_date|
  ordered_posts.each do |post|
    month = post.created_at.strftime('%B %Y')
    posts_by_date[month] ||= []
    posts_by_date[month] << post
  end
end

globals = {
  'posts_by_permalink' => posts_by_permalink,
  'posts_by_date' => posts_by_date
}

helpers do
  def render(filename, locals = {}, options = {:layout => true})
    locals = locals.merge(:request => request)
    options[:layout] ? Layouts['application.haml'].render(Templates[filename], locals) : Templates[filename].render(locals)
  end
end

application_layout = Layouts['application.haml']

get '/' do
  render('index.haml', globals.merge(:title => 'Home', :posts => ordered_posts))
end

get '/post/:permalink' do
  post = posts_by_permalink[params[:permalink]]
  render('show.haml', globals.merge(:title => post.title, :post => post))
end

get '/posts.rss' do                                                                                  
  content_type 'application/rss+xml', :charset => 'utf-8'
  render('index.builder', globals.merge(:posts => ordered_posts), :layout => false)
end

get '/posts/:month' do
  posts = posts_by_date[params[:month]] || []
  render('index.haml', globals.merge(:title => params[:month], :posts => posts))
end

get '/stylesheets/application.css' do
  content_type 'text/css', :charset => 'utf-8'
  Stylesheets['application.sass'].render
end