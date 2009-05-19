xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "blog.engledew.com"
    xml.description "Simon Engledew's Online Engineering Logbook"
    xml.link 'http://blog.engledew.com/'
    
    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.description post.content
        xml.pubDate post.created_at.strftime('%a, %d %b %Y %H:%M:%S %z')
        xml.link "http://blog.engledew.com/post/#{post.permalink}"
      end
    end
  end
end