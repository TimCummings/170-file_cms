# document.rb

# frozen_string_literal: true

# encapsulate behavior for content management system document
class Document < Resource
  EXT_TYPE = {
    '.md'  => 'text/html',
    '.txt' => 'text/plain'
  }.freeze

  def self.path
    build_path 'data'
  end

  def self.all
    super.map { |basename| new basename }
  end

  def self.versions(document_path)
    pattern = File.join(document_path, '*')
    Dir.glob(pattern).map { |path| File.basename(path) }
  end

  def self.load(document_path, version = nil)
    version ||= max_version_number(document_path)
    File.read File.join(document_path, version.to_s)
  end

  def self.name_error(name)
    name = name.strip

    if name.empty?
      'A name is required.'
    elsif all.any? { |document| document.name == name }
      "#{name} already exists."
    elsif File.extname(name).empty?
      'A valid document extension is required (e.g. .txt).'
    elsif !EXT_TYPE.key?(File.extname(name))
      "#{File.extname(name)} extension is not currently supported."
    end
  end

  def self.content_type(extname)
    EXT_TYPE[extname] || 'text/plain'
  end

  def self.exists?(document_path, version = nil)
    version ||= max_version_number(document_path).to_s
    File.file? File.join(document_path, version)
  end

  def self.save!(document_path, content = '')
    FileUtils.mkdir(document_path) unless exists?(document_path)
    version = max_version_number(document_path) + 1
    File.write File.join(document_path, version.to_s), content
  end

  def self.delete!(document_path)
    FileUtils.rm_r document_path
  end

  # return the path to the most recent version of the specified document
  def self.latest_version(document_path)
    File.join(document_path, max_version_number(document_path).to_s)
  end

  # return a document's highest (most recent) version number
  def self.max_version_number(document_path)
    versions(document_path).map(&:to_i).max || 0
  end

  attr_reader :name, :path, :extname, :content

  def initialize(document_name, content = '')
    @name = document_name
    @path = File.join self.class.path, document_name
    @extname = File.extname document_name
    @content = content
  end

  def name_error
    self.class.name_error name
  end

  def save!
    self.class.save! path, content
  end

  def delete!
    self.class.delete! path
  end

  def exists?(version = nil)
    self.class.exists? path, version
  end

  def content_type
    self.class.content_type extname
  end

  def load(version = nil)
    self.class.load path, version
  end

  def duplicate
    name_of_duplicate = File.basename(name, '.*') + '-copy' + extname
    self.class.new name_of_duplicate, load
  end
end
