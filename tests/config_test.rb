# coding: utf-8
require 'src/config.rb'
class ConfigTest < Test::Unit::TestCase
  def test_basic_methods_with_default_fixture
    config = Hercules::Config.new 'tests/fixtures/config.yml'
    assert_equal YAML.load_file('tests/fixtures/config.yml'), config.projects
    assert_equal ['target_directory', 'repository', 'token'], Hercules::Config.project_attributes
    assert_equal ['checkout_on_startup', 'checkouts_to_keep'], Hercules::Config.branch_attributes
    assert_equal ['master', 'test'], config.branches['test_project']
  end

  def test_config_attr_reader
    config = Hercules::Config.new 'tests/fixtures/config.yml'
    yml = YAML.load_file('tests/fixtures/config.yml')
    config.each do |k,v|
      assert_equal config[k], yml[k]
    end
  end

  def test_config_validation
    [ 'tests/fixtures/config_empty.yml', 'tests/fixtures/config_empty_projects.yml', 'tests/fixtures/config_partial_1.yml', 'tests/fixtures/config_partial_2.yml', 'tests/fixtures/config_partial_3.yml'].each do |p|
      assert_invalid_config(p) 
    end
    assert_nothing_raised do 
      config = Hercules::Config.new('tests/fixtures/config_empty_branches.yml')
    end
  end

  def test_config_with_global_attributes
    config = Hercules::Config.new 'tests/fixtures/config_global.yml'
    assert_equal "127.0.0.1", config.host
    assert_equal 8081, config.port
  end

  def assert_invalid_config path
    assert_raise(Hercules::InvalidConfig) do
      config = Hercules::Config.new(path)
    end
  end
end
