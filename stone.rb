#!/usr/bin/ruby

require 'rubygems'
require 'haml'
require 'sass'
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
  
  class BuilderEngine
    def initialize(source, options = {})
      @source = source
      @xml = Builder::XmlMarkup.new(options)
    end
    
    def render(binding = binding)
      eval("lambda { |xml| #{@source} }", binding).call(@xml)
    end
  end
end
