# coding: utf-8
class GitHandler
  def initialize(options)
    @options = options
  end

  def checkout_to_directory(branch)
    Git.export(@options['repository'], @options[branch]['target_directory'])
  end
end
