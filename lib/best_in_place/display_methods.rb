module BestInPlace
  module DisplayMethods  #:nodoc:
    module_function

    class Renderer
      attr_reader :method, :type, :attr, :helper_options, :proc

      def initialize(**opts)
        @method = opts[:method]
        @type = opts[:type]
        @attr = opts[:attr]
        @helper_options = opts[:helper_options]
        @proc = opts[:proc]
      end

      def render_json(object)
        case type
          when :model
            { display_as: object.send(method) }.to_json
          when :helper
            value = if helper_options
                      BestInPlace::ViewHelpers.send(method, object.send(attr), helper_options)
                    else
                      BestInPlace::ViewHelpers.send(method, object.send(attr))
                    end
            { display_as: value }.to_json
          when :proc
            { display_as: proc.call(object.send(attr)) }.to_json
          else
            '{}'
        end
      end
    end

    @@table = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }

    def lookup(klass, attr)
      foo = model_attributes(klass)[attr.to_s]
      foo == {} ? nil : foo
    end

    def add_model_method(klass, attr, display_as)
      model_attributes(klass)[attr.to_s] = Renderer.new(method: display_as.to_sym, type: :model)
    end

    def add_helper_method(klass, attr, helper_method, helper_options = nil)
      model_attributes(klass)[attr.to_s] = Renderer.new(method: helper_method.to_sym, type: :helper, attr: attr, helper_options: helper_options)
    end

    def add_helper_proc(klass, attr, helper_proc)
      model_attributes(klass)[attr.to_s] = Renderer.new(type: :proc, attr: attr, proc: helper_proc)
    end

    def model_attributes(klass)
      key = Utils.object_to_key(klass)
      @@table[key]
    end
  end
end
