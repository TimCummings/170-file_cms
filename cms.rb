# cms.rb

require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'redcarpet'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

EXT_TYPE = {
  '.md'  => 'text/html',
  '.txt' => 'text/plain'
}

def root
  File.expand_path '..', __FILE__
end

def data_path
  if ENV['RACK_ENV'] == 'test'
    File.join(root, 'test', 'data')
  else
    File.join(root, 'data')
  end
end

def load_content(file_path)
  content = File.read file_path
  headers['Content-Type'] = EXT_TYPE[File.extname(file_path)]

  case File.extname(file_path)
  when '.md' then render_markdown(content)
  else content
  end
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def user?
  session.key?('user')
end

def halt_unless_authorized
  unless user?
    session['message'] = 'You must be signed in to do that.'
    redirect '/', 401
  end
end

# index: view a list of files
get '/' do
  pattern = File.join(data_path, '*')
  @files = Dir.glob(pattern).map { |path| File.basename(path) }
  erb :index
end

# render new file form
get '/new' do
  halt_unless_authorized

  erb :new
end

# create a new file
post '/create' do
  halt_unless_authorized

  @file_name = params['file_name']
  file_path = File.join(data_path, @file_name)

  if @file_name.strip.empty?
    session['message'] = 'A name is required.'
    status 422
    erb :new
  else
    FileUtils.touch file_path
    session['message'] = "#{@file_name} was created."
    redirect '/'
  end
end

# view a file by name
get '/:file_name' do
  @file_name = params['file_name']
  file_path = File.join(data_path, @file_name)

  if File.file? file_path
    load_content file_path
  else
    session['message'] = "#{@file_name} does not exist."
    redirect '/'
  end
end

# render edit file form
get '/:file_name/edit' do
  halt_unless_authorized

  @file_name = params['file_name']
  file_path = File.join(data_path, @file_name)

  if File.file? file_path
    @content = File.read file_path
    erb :edit
  else
    session['message'] = "#{@file_name} does not exist."
    redirect '/'
  end
end

# edit a file by name
post '/:file_name' do
  halt_unless_authorized

  @file_name = params['file_name']
  file_path = File.join(data_path, @file_name)
  @content = params['content']

  if File.file? file_path
    File.write file_path, @content
    session['message'] = "#{@file_name} has been updated."
  else
    session['message'] = "#{@file_name} does not exist."
  end

  redirect '/'
end

# delete a file
post '/:file_name/delete' do
  halt_unless_authorized

  @file_name = params['file_name']
  file_path = File.join(data_path, @file_name)

  FileUtils.rm file_path
  session['message'] = "#{@file_name} was deleted."
  redirect '/'
end

# render signin form
get '/users/signin' do
  erb :signin
end

# attempt to sign in the user with provided credentials
post '/users/signin' do
  if params['username'] == 'admin' && params['password'] == 'secret'
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
