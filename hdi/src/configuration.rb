require 'compass'
Compass.add_project_configuration('config.rb')
configuration.use_extensions_for_page_links = true
configuration.sass_options = Compass.sass_engine_options
configuration.haml_options = { :format => :html5, :attr_wrapper => '"' }
