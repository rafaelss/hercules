ROOT = File.join(File.dirname(__FILE__), '/')
puts "HDI root is at" + File.expand_path(ROOT)
output_style      = :compressed
project_path      = ROOT                                            # must be set for Compass to work
sass_dir          = "/usr/lib/ruby/gems/1.8/gems/compass-0.10.5"    # dir containing Sass / Compass source files
http_path         = "/site/"                                        # root when deployed
css_dir           = "/src/pages/"                                   # final CSS
