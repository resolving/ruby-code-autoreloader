# frozen_string_literal: true

require 'spec_helper'
require 'set'

RSpec.describe RubyCodeAutoreloader::ClassLoader do
  describe '#remove_constant' do
    let(:const_to_delete) { 'KillMe' }
    let(:const_to_save) { 'SaveMe' }
    let(:module_name) { "::#{const_to_save}::#{const_to_delete}" }

    it 'unloads the given constant with submodule' do
      Object.const_set(const_to_save, Module.new)
      mod = Object.const_get(const_to_save)
      mod.const_set(const_to_delete, Module.new) #=> 'SaveMe::KillMe'

      expect { Object.const_get(module_name) }.not_to raise_error

      subject.remove_constant(module_name)

      expect { Object.const_get(const_to_save) }.not_to raise_error
      expect { Object.const_get(const_to_delete) }.to raise_error(NameError)
    
    ensure
      subject.remove_constant(const_to_save)
    end

    it 'unloads the given simple constant' do
      Object.const_set(const_to_delete, Module.new)

      expect { Object.const_get(const_to_delete) }.not_to raise_error

      subject.remove_constant(const_to_delete)

      expect { Object.const_get(const_to_delete) }.to raise_error(NameError)
    end
  end

  describe '#qualified_const_defined?' do
    let(:const_to_define) { 'SaveMe' }
    let(:not_defined_const) { 'KillMe' }

    it 'checks that given constant defined' do
      Object.const_set(const_to_define, Module.new)

      expect(subject.qualified_const_defined?(const_to_define)).to be_truthy
    
    ensure
      subject.remove_constant(const_to_define)
    end

    it 'checks that given constant not defined' do
      expect(subject.qualified_const_defined?(not_defined_const)).to be_falsey
    end

    it 'raises error if given wrong constant name' do
      expect { subject.qualified_const_defined?('') }.to raise_error(NameError)
    end
  end

  describe '#normalize_const' do
    it 'handles double colon at start for simple module' do
      expect(subject.normalize_const('::MyClass')).to eq('MyClass')
    end

    it 'handles double colon at start' do
      expect(subject.normalize_const('::MyModule::MyClass')).to eq('MyModule::MyClass')
    end

    it 'handles ::Object class at start' do
      expect(subject.normalize_const('::Object::MyClass')).to eq('MyClass')
    end

    it 'handles singleton class definition #<Class:MyClass>' do
      expect(subject.normalize_const('#<Class:MyClass>')).to eq('MyClass')
    end
  end

  describe '#update_autoloaded_classes' do
    let(:current_file_path) { 'lib/index.rb' }
    let(:module_to_include) { 'Index' }
    let(:another_module) { 'AnotherModule' }
    let(:class_loaded_prev) { 'ClassLoadedPreviously' }
    let(:loaded_classes) { Set[class_loaded_prev] }

    it 'updates loaded classes var with new modules, that were defined inside the given file. New modules name should
        have the same name as the given file' do
      existed_modules = ObjectSpace.each_object(Module).to_a

      Object.const_set(module_to_include, Module.new)
      Object.const_set(another_module, Module.new)

      subject.update_autoloaded_classes(current_file_path, loaded_classes, existed_modules)

      expect(loaded_classes).to match([class_loaded_prev, module_to_include])
      
    ensure
      [module_to_include, another_module].each {|const| subject.remove_constant(const) }
    end
  end
end
