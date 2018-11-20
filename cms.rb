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

def build_path(path_name)
  if ENV['RACK_ENV'] == 'test'
    File.join(root, 'test', path_name)
  else
    File.join(root, path_name)
  end
end

def set_file_info
  @file_name = params['file_name']
  @file_path = File.join(build_path('data'), @file_name)
end

def load_content(file_path)
  content = File.read file_path
  headers['Content-Type'] = EXT_TYPE[File.extname(file_path)] || 'text/plain'

  case File.extname(file_path)
  when '.md' then render_markdown(content)
  else content
  end
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def error_for_file_name(file_name)
  file_name = file_name.strip
  file_extension = File.extname(file_name)

  if file_name.empty?
    'A name is required.'
  elsif file_extension.empty?
    'A valid file extension is required (e.g. .txt).'
  elsif !EXT_TYPE.key?(file_extension)
    "#{file_extension} extension is not currently supported."
  end
end

def authentic_user?(username, password)
  users_path = File.join(build_path('config'), 'users.yml')
  users = Psych.load_file(users_path)
  users.key?(username) && BCrypt::Password.new(users[username]) == password
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

# index: view a list of files
get '/' do
  pattern = File.join(build_path('data'), '*')
  @files = Dir.glob(pattern).map { |path| File.basename(path) }
  erb :index
end

# render new file form
get '/new' do
  redirect_unless_authorized
  erb :new
end

# create a new file
post '/create' do
  redirect_unless_authorized

  set_file_info

  error = error_for_file_name(@file_name)
  if error
    status 422
    session['message'] = error
    erb :new
  else
    FileUtils.touch @file_path
    session['message'] = "#{@file_name} was created."
    redirect '/'
  end
end

# view a file by name
get '/:file_name' do
  set_file_info
  if File.file? @file_path
    load_content @file_path
  else
    session['message'] = "#{@file_name} does not exist."
    redirect '/'
  end
end

# render edit file form
get '/:file_name/edit' do
  redirect_unless_authorized

  set_file_info
  if File.file? @file_path
    @content = File.read @file_path
    erb :edit
  else
    session['message'] = "#{@file_name} does not exist."
    redirect '/'
  end
end

# edit a file by name
post '/:file_name' do
  redirect_unless_authorized

  set_file_info
  @content = params['content']

  if File.file? @file_path
    File.write @file_path, @content
    session['message'] = "#{@file_name} has been updated."
  else
    session['message'] = "#{@file_name} does not exist."
  end

  redirect '/'
end

# delete a file
post '/:file_name/delete' do
  redirect_unless_authorized

  set_file_info

  FileUtils.rm @file_path
  session['message'] = "#{@file_name} was deleted."
  redirect '/'
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
