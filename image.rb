# image.rb

# frozen_string_literal: true

# encapsulate behavior for content management system image
class Image < Resource
  def self.path
    build_path File.join('public', 'images')
  end

  def self.all
    super.map { |image_name| new image_name }
  end

  def self.error(image_name, image_file)
    if image_file.nil?
      'Please select an image to upload.'
    elsif image_name.empty?
      'An image name is required.'
    elsif all.any? { |image| image.name == image_name }
      "#{image_name} already exists."
    end
  end

  def self.exists?(image_name)
    File.file? File.join(path, image_name)
  end

  def self.save!(image_path, image_file)
    File.open(image_path, 'wb') do |file|
      file.write File.read(image_file)
    end
  end

  def self.upload(temp_image)
    new temp_image[:filename], temp_image[:tempfile]
  end

  def self.delete!(image_path)
    FileUtils.rm image_path
  end

  attr_reader :name, :path, :tempfile

  def initialize(image_name, tempfile = nil)
    @name = image_name
    @path = File.join self.class.path, image_name
    @tempfile = tempfile
  end

  def error
    self.class.error name, tempfile
  end

  def exists?
    self.class.exists? name
  end

  def save!
    self.class.save! path, tempfile
  end

  def delete!
    self.class.delete! path
  end
end
