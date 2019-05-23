# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyCodeAutoreloader do
  let(:classes_should_be_loaded) { ['TestClasses::FooClass', 'TestClasses::TestClass'] }
  let(:autoloadable_paths) { ['spec/support/test_classes'] }
  let(:config) do
    {
      autoloadable_paths: autoloadable_paths,
      autoreload_enabled: true
    }
  end
  
  describe '#config' do
    it 'returns default config for not initiated module' do
      expect(subject.config).to be_kind_of(RubyCodeAutoreloader::Config)
      expect(subject.config.autoloadable_paths).to be_empty
    end
  end

  describe '#configure' do
    let(:autoloadable_paths) { ['lib/tools', 'lib/tasks'] }

    it 'sets configuration by merging custom params with defaults' do
      expect(subject.configure(autoloadable_paths: autoloadable_paths)).to be_kind_of(RubyCodeAutoreloader::Config)
      expect(subject.config.autoloadable_paths).to match(autoloadable_paths)
    end
  end

  describe '#autoreload_enabled?' do
    let(:autoreload_enabled) { false }

    it 'equals to the initialized mode' do
      expect(subject.configure(autoreload_enabled: autoreload_enabled)).to be_kind_of(RubyCodeAutoreloader::Config)
      expect(subject.autoreload_enabled?).to eq(autoreload_enabled)
    end
  end

  describe '#start' do
    it 'initialize vars, sets ActiveSupport::Dependencies mechanism, loads the given autoloadable paths and
        sets file watchers' do
      subject.configure(config)

      expect(subject.config.file_watchers).to be_empty
      expect(subject.all_autoloaded_classes).to be_empty
      expect(ActiveSupport::Dependencies.mechanism).to eq(:load)
      
      subject.start

      expect(subject.config.file_watchers).not_to be_empty
      expect(subject.all_autoloaded_classes).to match(classes_should_be_loaded)
    ensure
      subject.clear
    end
  end

  describe '#clear' do
    it 'clears the variables before reloading' do
      subject.configure(config)
      subject.start

      expect(subject.all_autoloaded_classes).to match(classes_should_be_loaded)
      
      subject.clear
      
      expect(subject.config.file_watchers).not_to be_empty
      
      expect(subject.instance_variable_get("@existing_modules_before_load")).to be_empty
      expect(subject.instance_variable_get("@autoloaded_files")).to be_empty
      expect(subject.all_autoloaded_classes).to be_empty
    end
  end

  describe '#load_paths' do
    it 'loads files from the given paths ' do
      subject.configure(config)
      subject.init
      expect(subject.all_autoloaded_classes).to be_empty

      subject.load_paths
      
      expect(subject.all_autoloaded_classes).to match(classes_should_be_loaded)
    ensure
      subject.clear
    end
  end

  describe '#reload' do
    let(:config_always_reload) do
      {
        autoloadable_paths: [tmp_dir], # tmp folder
        autoreload_enabled: true,
        reload_only_on_change: false
      }
    end
    
    let(:tmp_dir) { 'tmp' }
    let(:test_file_path) { "#{tmp_dir}/test_module.rb" }
    let(:new_method_result) { 'Hi from new method' }
    let(:test_module) { 'TestModule' }
    let(:new_method) { 'hello' }
    let(:classes_should_be_loaded) { [test_module] }
    
    before do
      Dir.mkdir(tmp_dir) unless Dir.exist?(tmp_dir)
      file = File.new(test_file_path, 'w')
      begin
        file.puts "module #{test_module}"
        file.puts 'end'
      ensure
        file.close unless file.nil?
      end
    end

    after do
      File.delete(test_file_path) if File.file?(test_file_path)
      Dir.rmdir(tmp_dir) if Dir.exist?(tmp_dir)
    end
    
    it 'reloads files from the given paths' do
      subject.configure(config_always_reload)
      subject.start
      
      expect(subject.all_autoloaded_classes).to match(classes_should_be_loaded)

      # Change new file in tmp folder, add new method
      file = File.new(test_file_path, 'w')
      begin
        file.puts "module #{test_module}"
        file.puts "  def self.#{new_method}"
        file.puts "    '#{new_method_result}'"
        file.puts '  end'
        file.puts 'end'
      ensure
        file.close unless file.nil?
      end
      
      # Trying to call this new method from the loaded test class. It should raise an Error
      expect { test_module.constantize.send(new_method.to_sym) }.to raise_error(NameError)
      
      subject.reload
      
      # Try to call some  method from the loaded test class. It should return some test string
      expect(test_module.constantize.send(new_method.to_sym)).to eq(new_method_result)
    ensure
      subject.clear
    end
  end

  describe '#all_autoloaded_classes' do
    it 'returns empty array for not initialized module' do
      expect(subject.all_autoloaded_classes).to be_empty
    end
  end
end
