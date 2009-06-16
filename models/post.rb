class Post
  def initialize(filename)
    @filename = File.basename(filename, File.extname(filename))
    
    match = File.open(filename, 'r').read.match(/(.*?)^$(.*)/m)
    
    attributes = YAML.load(match[1])

    @content = RedCloth.new(match[2]).to_html
    @category = attributes['category']
    @published = attributes['published']
    @created_at = DateTime.parse(attributes['created_at'])
    @title = attributes['title']
    
    @permalink = @title.downcase.gsub(/[^-.a-z0-9 ]/, '').tr(' ', '-').squeeze('-')
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
  
  attr_reader :content, :published, :created_at, :title, :permalink, :category, :filename
end