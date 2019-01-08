# cms.rb

require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'redcarpet'
require 'psych'
require 'bcrypt'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

EXT_TYPE = {
  '.md'  => 'text/html',
  '.txt' => 'text/plain'
}

def root
  File.expand_path('..', __FILE__)
end

def config_path
  build_path 'config'
end

def data_path
  build_path 'data'
end

def images_path
  build_path 'public/images'
end

def documents
  pattern = File.join(data_path, '*')
  Dir.glob(pattern).map { |path| File.basename(path) }
end

def images
  pattern = File.join(images_path, '*')
  Dir.glob(pattern).map { |path| File.basename(path) }
end

def versions(document_path)
  pattern = File.join(document_path, '*')
  Dir.glob(pattern).map { |path| File.basename(path) }
end

def all_users
  Psych.load_file(File.join(config_path, 'users.yml'))
end

helpers do
  def render_markdown(text)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(text)
  end

  def sorted_versions(document_path)
    versions(document_path).sort { |a, b| b.to_i <=> a.to_i }
  end
end

# create a new user
post '/users' do
  @new_username = params['new_username']

  error = error_for_new_user(@new_username, params['new_password'], params['confirm_new_password'])
  if error
    session['message'] = error
    status 422
    erb :signin
  else
    digest = BCrypt::Password.create params['new_password']
    add_user @new_username, digest
    session['user'] = @new_username
    session['message'] = "Created user #{@new_username}."
    redirect '/'
  end
end

# render signin form
get '/users/signin' do
  erb :signin
end

# attempt to sign in the user with provided credentials
post '/users/signin' do
  if authentic_user?(params['username'], params['password'])
    session['user'] = params['username']
    session['message'] = 'Welcome!'
    redirect '/'
  else
    session['message'] = 'Invalid Credentials'
    status 401
    erb :signin
  end
end

# sign out
post '/users/signout' do
  session.delete 'user'
  session['message'] = 'You have been signed out.'
  redirect '/'
end

# delete the current user
post '/users/delete' do
  redirect_unless_authorized

  current_user = session.delete('user')
  delete_user current_user
  session['message'] = "User #{current_user} has been deleted."
  redirect '/'
end

# view a list of images
get '/images' do
  erb :images
end

# upload a new image
post '/images' do
  redirect_unless_authorized

  @image = params['image_upload']

  error = error_for_image(@image)
  if error
    session['message'] = error
    status 422
    erb :images
  else
    File.open(File.join(images_path, @image[:filename]), 'wb') do |file|
      file.write File.read(params['image_upload'][:tempfile])
    end
    session['message'] = "#{@image[:filename]} was uploaded."
    redirect '/images'
  end
end

# view an image
get '/images/:image_name' do
  set_image_info
  erb :image
end

# delete an image
post '/images/:image_name/delete' do
  redirect_unless_authorized

  set_image_info
  FileUtils.rm @image_path
  session['message'] = "#{@image_name} was deleted."
  redirect '/images'
end

# index: view a list of documents
get '/' do
  erb :index
end

# render new document form
get '/new' do
  redirect_unless_authorized
  erb :new
end

# create a new document
post '/create' do
  redirect_unless_authorized

  set_document_info

  error = error_for_document_name(@document_name)
  if error
    status 422
    session['message'] = error
    erb :new
  else
    save_document @document_path
    session['message'] = "#{@document_name} was created."
    redirect '/'
  end
end

# view a document by name
get '/:document_name' do
  set_document_info

  if document_exists? @document_path
    render_content @document_path
  else
    session['message'] = "#{@document_name} does not exist."
    redirect '/'
  end
end

# duplicate a document by name
post '/:document_name/duplicate' do
  redirect_unless_authorized

  set_document_info
  copy_name = File.basename(@document_name, '.*') + '-copy' + File.extname(@document_name)
  copy_path = File.join File.dirname(@document_path), copy_name

  if document_exists?(copy_path)
    session['message'] = "#{copy_name} already exists."
  else
    save_document copy_path, load_content(@document_path)
    session['message'] = "Duplicated #{@document_name} as #{copy_name}."
  end

  redirect '/'
end

# render edit document form
get '/:document_name/edit' do
  redirect_unless_authorized

  set_document_info
  if document_exists? @document_path
    @content = load_content @document_path
    erb :edit
  else
    session['message'] = "#{@document_name} does not exist."
    redirect '/'
  end
end

# edit a document by name
post '/:document_name' do
  redirect_unless_authorized

  set_document_info
  @content = params['content']

  if document_exists? @document_path
    save_document @document_path, @content
    session['message'] = "#{@document_name} has been updated."
  else
    session['message'] = "#{@document_name} does not exist."
  end

  redirect '/'
end

# delete a document
post '/:document_name/delete' do
  redirect_unless_authorized

  set_document_info
  FileUtils.rm_r @document_path
  session['message'] = "#{@document_name} was deleted."
  redirect '/'
end

# view a list of document versions
get '/:document_name/versions' do
  set_document_info
  erb :versions
end

# view a specific version of a document
get '/:document_name/:version' do
  set_document_info
  @version = params['version']

  if document_exists? @document_path, @version
    render_content @document_path, @version
  else
    session['message'] = "Version #{@version} of #{@document_name} does not exist."
    redirect '/'
  end
end

private

def build_path(path_name)
  if ENV['RACK_ENV'] == 'test'
    File.join(root, 'test', path_name)
  else
    File.join(root, path_name)
  end
end

def set_document_info
  @document_name = params['document_name']
  @document_path = File.join(data_path, @document_name)
end

def load_content(document_path, version=nil)
  version ||= max_version_number(document_path)
  File.read File.join(document_path, version.to_s)
end

def render_content(document_path, version=nil)
  headers['Content-Type'] = EXT_TYPE[File.extname(document_path)] || 'text/plain'

  case File.extname(document_path)
  when '.md' then render_markdown load_content(document_path, version)
  else load_content(document_path, version)
  end
end

def error_for_document_name(name)
  name = name.strip

  if name.empty?
    'A name is required.'
  elsif documents.include? name
    "#{name} already exists."
  elsif File.extname(name).empty?
    'A valid document extension is required (e.g. .txt).'
  elsif !EXT_TYPE.key?(File.extname(name))
    "#{File.extname(name)} extension is not currently supported."
  end
end

def document_exists?(path, version=nil)
  version ||= max_version_number(path).to_s
  File.file? File.join(path, version)
end

def save_document(path, content='')
  FileUtils.mkdir(path) unless document_exists?(path)
  version = max_version_number(path) + 1
  File.write File.join(path, version.to_s), content
end

# return the path to the most recent version of the specified document
def latest_version(document_path)
  File.join(document_path, max_version_number(document_path).to_s)
end

# return a document's highest (most recent) version number
def max_version_number(document_path)
  versions(document_path).map(&:to_i).max || 0
end

def set_image_info
  @image_name = params['image_name']
  @image_path = File.join(images_path, @image_name)
end

def error_for_image(image)
  return 'Please select an image to upload.' if image.nil?

  image_name = image[:filename].strip

  if image_name.empty?
    'An image name is required.'
  elsif images.index(image_name)
    "#{image_name} already exists."
  end
end

def add_user(username, digest)
  users = all_users
  users[username] = digest

  File.open(File.join(config_path, 'users.yml'), 'w') do |file|
    file.write Psych.dump(users)
  end
end

def error_for_new_user(new_username, new_password, confirm_new_password)
  if new_username.nil? || new_username.strip.empty?
    'A new username is required.'
  elsif new_password.nil? || new_password.strip.empty?
    'A new password is required.'
  elsif confirm_new_password.nil? || confirm_new_password.strip.empty?
    'New password must be confirmed.'
  elsif new_password != confirm_new_password
    "Passwords don't match."
  elsif all_users.key? new_username
    "User #{new_username} already exists."
  end
end

def delete_user(username)
  users = all_users
  users.delete username

  File.open(File.join(config_path, 'users.yml'), 'w') do |file|
    file.write Psych.dump(users)
  end
end

def authentic_user?(username, password)
  all_users.key?(username) && BCrypt::Password.new(all_users[username]) == password
end

# true if user is signed in
def user?
  session.key? 'user'
end

def redirect_unless_authorized
  unless user?
    session['message'] = 'You must be signed in to do that.'
    redirect '/'
  end
end
