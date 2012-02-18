require "mustache"

module Raptor
  class FindsLayouts
    def self.find(name)
      from_path_dir = "views/#{name}/layout.html.mustache"
      from_toplevel =  "views/layout.html.mustache"
      if File.exists?(from_path_dir)
        Raptor::Layout.new(from_path_dir)
      elsif File.exists?(from_toplevel)
        Raptor::Layout.new(from_toplevel)
      else
        NullLayout.new
      end
    end
  end

  class NullLayout
    def ==(other)
      other.is_a?(NullLayout)
    end

    def render(template)
      template.render
    end
  end

  class Layout < Mustache
    attr_reader :layout_path
    def initialize(layout_path)
      @layout_path = layout_path
    end

    def self.render(inner, name)
      FindsLayouts.find(name).render(inner)
    end

    def render(template)
      super(:yield => template.render)
    end

    def template
      File.new(@layout_path).read
    end

    def ==(other)
      other.is_a?(Layout) && 
        layout_path == other.layout_path
    end
  end

  class Template < Mustache
    @raise_on_context_miss = true
    def initialize(presenter, template_path)
      @presenter = presenter
      @template_path = template_path
    end

    def self.render(presenter, template_path)
      new(presenter, template_path).render
    end

    def template
      File.new(full_template_path).read
    end

    def full_template_path
      template_path = @template_path
      template_path = "/#{template_path}" unless template_path =~ /^\//
      "views#{template_path}"
    end

    def method_missing(method_name, *args, &block)
      @presenter.send(method_name)
    end

    def respond_to?(method_name)
      @presenter.respond_to?(method_name)
    end
  end
end
