xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "toothygoose.com"
    xml.description "Online engineering logbook of Simon Engledew"
    xml.link 'http://www.toothygoose.com/'
    
    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.description RedCloth.new(post.content).to_html
        xml.pubDate post.created_at.strftime('%a, %d %b %Y %H:%M:%S %z')
        xml.link "http://www.toothygoose.com/post/#{post.permalink}"
      end
    end
  end
end