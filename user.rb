# user.rb

# frozen_string_literal: true

require 'bcrypt'

# encapsulate behavior for content management system user
class User < Resource
  def self.path
    build_path 'config'
  end

  def self.all
    Psych.load_file(File.join(User.path, 'users.yml'))
  end

  def self.save!(username, password)
    users = all
    users[username] = BCrypt::Password.create password

    File.open(File.join(path, 'users.yml'), 'w') do |file|
      file.write Psych.dump(users)
    end
  end

  def self.delete!(username)
    users = all
    users.delete username

    File.open(File.join(path, 'users.yml'), 'w') do |file|
      file.write Psych.dump(users)
    end
  end

  # rubocop:disable Metrics/MethodLength
  def self.error_for_new(new_username, new_password, confirm_new_password)
    if empty? new_username
      'A new username is required.'
    elsif empty? new_password
      'A new password is required.'
    elsif empty? confirm_new_password
      'New password must be confirmed.'
    elsif new_password != confirm_new_password
      "Passwords don't match."
    elsif all.key? new_username
      "User #{new_username} already exists."
    end
  end
  # rubocop:enable Metrics/MethodLength

  def self.authentic?(username, password)
    all.key?(username) && BCrypt::Password.new(all[username]) == password
  end

  def self.empty?(field)
    field.nil? || field.strip.empty?
  end

  attr_reader :username

  def initialize(username, password = nil, confirm_password = nil)
    @username = username
    @password = password
    @confirm_password = confirm_password
  end

  def error
    self.class.error_for_new(username, @password, @confirm_password)
  end

  def save!
    self.class.save! username, @password
  end

  def authentic?
    self.class.authentic? username, @password
  end

  def delete!
    self.class.delete! username
  end
end
