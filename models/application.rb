module EngineFactory
    # @cache = Cache.new
  class << self
    def load(root, filename)
      source = File.open(File.join(root, filename), 'r').read
      case extension = File.extname(filename)[1..-1]
        when 'haml' then Haml::Engine.new(source)
        when 'sass' then Sass::Engine.new(source, :load_paths => [root], :style => ENV['RACK_ENV'] == 'development' ? :expanded : :compressed)
        when 'builder' then Stone::BuilderEngine.new(source, :indent => 2)
        else raise "unknown engine extension: #{extension}"
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
    @cache[filename] ||= @block.call(EngineFactory.load(@root, filename))
  end
end