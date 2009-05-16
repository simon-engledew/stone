#!/usr/bin/ruby

require 'rubygems'
require 'haml'
require 'sass'
require 'yaml'
require 'builder'

module Stone
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

    def escape(s)
      s.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/n) {
        '%'+$1.unpack('H2'*$1.size).join('%').upcase
      }.tr(' ', '+')
    end
  end
  
  class Renderer
    def initialize(engine, locals = {}, globals = {}, bound_content = {})
      @engine = engine
      @locals = locals
      @globals = globals
      @bound_content = bound_content
    end
    
    include Helpers
  
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
  
    def template(filename, locals = {})
      Templates[filename].render(self.locals.merge(locals), globals, bound_content)
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

ROOT = File.expand_path(File.dirname(__FILE__)) unless Object.const_defined?(:ROOT)

module Templates
  @root = File.join(ROOT, 'templates')
  
  class << self
    def [](filename)
      Stone::Template.new(Stone::EngineFactory.load(File.join(@root, filename)))
    end
  end
end

module Layouts
  @root = File.join(ROOT, 'layouts')
  
  class << self
    def [](filename)
      Stone::Layout.new(Stone::EngineFactory.load(File.join(@root, filename)))
    end
  end
end

module Stylesheets
  @root = File.join(ROOT, 'sass')
  
  class << self
    def [](filename)
      Stone::EngineFactory.load(File.join(@root, filename), :load_paths => [@root], :style => :expanded)
    end
  end
end

