require "tilt"

module Raptor
  class FindsLayouts
    LAYOUT_FILENAME = 'layout.html.erb'
    def self.find(path)
      in_same_dir = File.join('views', path, LAYOUT_FILENAME)
      in_root_dir = File.join('views', LAYOUT_FILENAME)
      if File.exist?(in_same_dir)
        Layout.new(in_same_dir)
      elsif File.exist?(in_root_dir)
        Layout.new(in_root_dir)
      else
        NullLayout
      end
    end
  end

  class NullLayout
    def self.render(inner)
      inner.render
    end
  end

  class Layout
    attr_reader :path
    def initialize(path)
      @path = path
    end

    def ==(other)
      other.is_a?(Layout) &&
        other.path == path
    end

    def render(inner)
      inner_result = inner.render
      Tilt.new(@path).render(inner.presenter) { inner_result }
    end
  end

  class ViewContext
    def initialize(presenter)
      @presenter = presenter
      @content_areas = {}
    end

    def content_for(name, &block)
      @content_areas[name] = block[]
    end

    def yield_content_for(name)
      @content_areas[name]
    end

    def method_missing(message, *args, &block)
      @presenter.send(message, *args, &block)
    end
  end

  class Template
    attr_reader :presenter
    def initialize(presenter, tilt)
      @presenter = presenter
      @tilt = tilt
    end

    def render
      @tilt.render(@presenter)
    end

    def self.from_path(presenter, template_path)
      path = full_template_path(template_path)
      tilt = Tilt.new(path)
      new(ViewContext.new(presenter), tilt)
    end

    def self.full_template_path(template_path)
      template_path = "/#{template_path}" unless template_path =~ /^\//
      "views#{template_path}"
    end
  end
end
