#!/usr/bin/ruby

require 'rubygems'
require 'haml'
require 'sass'
require 'yaml'
require 'builder'

module Stone
  class Cache
    def initialize
      @cache = {}
    end

    def read(*key, &block)
      if (value = self[*key]).nil? and block_given?
        return (self[*key] = block.call)
      end
      return value
    end

    def [](*args)
      @cache[Marshal.dump(args)]
    end

    def []=(*args)
      @cache[Marshal.dump(args[0..-2])] = args[-1]
    end
    
    def reset!
      @cache = {}
    end
  end
  
  class Renderer
    def initialize(engine, locals = {}, globals = {}, bound_content = {})
      @engine = engine
      @locals = locals
      @globals = globals
      @bound_content = bound_content
    end
    
    def render
      proc do
        (globals.merge(locals)).
          map{|key, value|[:"@#{key}", value]}.
          reject{|key, value|instance_variable_defined? key}.
          each{|key, value|instance_variable_set(key, value)}

        engine.render(binding) do |*args|
          bound_content[(args.first || :yield).to_sym]
        end
      end.call
    end  
    
    def content_for(identifier, &block)
      @bound_content[identifier.to_sym] ||= []
      @bound_content[identifier.to_sym] << capture_haml(&block)
    end
  
    attr_reader :engine, :bound_content, :locals, :globals
  end

  class Template
    def initialize(engine)
      @engine = engine
    end
 
    def render(locals = {}, globals = {}, bound_content = {}, &block)
      Renderer.new(@engine, locals, globals, bound_content).render(&block)
    end
  end

  class Layout < Template
    def render(fragment, locals = {}, globals = {}, bound_content = {})
      bound_content[:yield] = fragment.render(locals, globals, bound_content)
      super(locals, globals, bound_content)
    end
  end

  module EngineFactory
    # @cache = Cache.new
    
    class << self
      
      def load(filename, options = {})
        
        source = File.open(filename, 'r').read
        case extension = File.extname(filename)
          when '.haml' then Haml::Engine.new(source, options)
          when '.sass' then Sass::Engine.new(source, options)
          when '.builder' then Stone::BuilderEngine.new(source, options)
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
    def initialize(root, options = {}, &block)
      @root = root
      @options = options
      @block = block || proc {|engine| engine}
      self.reload!
    end

    def reload!
      @cache = {}
    end

    def [](filename)
      filename = File.join(@root, filename)
      @cache[filename] ||= @block.call(Stone::EngineFactory.load(filename, @options))
    end
  end

  class BuilderEngine
    def initialize(source, options)
      @source = source
      @options = options
    end
    
    def render(binding = binding)
      eval("xml = Builder::XmlMarkup.new(:indent => 2);#{source};xml.to_s", binding)
    end
    
    attr_reader :source, :options
  end
end
