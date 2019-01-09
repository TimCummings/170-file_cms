# resource.rb

# frozen_string_literal: true

# encapsulate generic behavior for content management system resource
class Resource
  def self.build_path(path_name)
    if ENV['RACK_ENV'] == 'test'
      File.join(root, 'test', path_name)
    else
      File.join(root, path_name)
    end
  end

  def self.all
    pattern = File.join(path, '*')
    Dir.glob(pattern).map { |path| File.basename(path) }
  end
end
