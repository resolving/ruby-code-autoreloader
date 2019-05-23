# frozen_string_literal: true

module RubyCodeAutoreloader
  module ClassLoader
    module_function

    def remove_constant(klass)
      normalized = normalize_const(klass)

      constants = normalized.split('::')
      to_remove = constants.pop

      if constants.empty?
        parent = Object
      else
        parent_name = constants.join('::')
        return unless qualified_const_defined?(parent_name)
        parent = parent_name.constantize
      end

      begin
        parent.const_get(to_remove, false) # check if constant to_remove exists
        parent.instance_eval { remove_const to_remove }
      rescue NameError
        # The constant is no longer reachable, just skip it.
      end
    end

    # Is the provided constant path defined?
    def qualified_const_defined?(path)
      Object.const_defined?(path, false)
    end

    def normalize_const(const)
      # Normalize ::Foo, ::Object::Foo, Object::Foo, Object::Object::Foo, #<Class:#<Class:Foo>> etc.
      # as Foo.
      return unless const

      klass = const.to_s.sub(%r{\A(#<Class:)+}, '').sub(%r{(>)+\z}, '')
      klass.sub(%r{\A::}, '').sub(%r{\A(Object::)+}, '')
    end

    def update_autoloaded_classes(current_file_path, loaded_classes, existed_modules)
      loaded_file_const = current_file_path.split('/').pop&.chomp('.rb')&.camelize.to_s

      new_modules = ObjectSpace.each_object(Module).to_a - existed_modules

      # Add constants to `autoloaded_classes` only if file name is equal to the Class/Module name defined inside the file
      # It's for excluding classes that weren't defined inside the file but was loaded too.
      # For example we are loading from `index.rb` and `new_modules` contains
      # [::Endpoints::Notes::Index, ActiveRecord::Errors, Endpointflux] items.
      # Then only `::Endpoints::Notes::Index` will be included to `autoloaded_classes`, because it ends with `Index` name.
      # It will prevent removing constants that weren't defined in autoloaded files, otherwise it will leads to errors
      # during the reloading process

      new_modules.each do |constant|
        normalized_const = normalize_const(constant)
        loaded_const = normalized_const&.split('::').pop

        loaded_classes.add(normalized_const) if loaded_const && loaded_file_const && loaded_const == loaded_file_const
      end
    end
  end
end
