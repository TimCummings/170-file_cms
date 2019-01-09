# cms.rb

# frozen_string_literal: true

require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'redcarpet'
require 'psych'

require_relative 'resource'
require_relative 'user'
require_relative 'document'
require_relative 'image'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

def root
  File.expand_path(__dir__)
end

def render_content(document, version = nil)
  headers['Content-Type'] = document.content_type
  case document.extname
  when '.md' then render_markdown document.load(version)
  else document.load(version)
  end
end

helpers do
  def render_markdown(text)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(text)
  end

  def sorted_versions(document_path)
    Document.versions(document_path).sort { |a, b| b.to_i <=> a.to_i }
  end
end

# create a new user
post '/users' do
  @user = User.new(params['new_username'], params['new_password'],
                   params['confirm_password'])

  error = @user.error
  if error
    handle_error 422, error, :signin
  else
    @user.save!
    session['user'] = @user.username
    flash "Created user #{@user.username}."
    redirect '/'
  end
end

# render signin form
get '/users/signin' do
  erb :signin
end

# attempt to sign in the user with provided credentials
post '/users/signin' do
  @user = User.new(params['username'], params['password'])

  if @user.authentic?
    session['user'] = @user.username
    flash 'Welcome!'
    redirect '/'
  else
    handle_error 401, 'Invalid Credentials', :signin
  end
end

# sign out
post '/users/signout' do
  session.delete 'user'
  flash 'You have been signed out.'
  redirect '/'
end

# delete the current user
post '/users/delete' do
  redirect_unless_authorized

  @user = User.new(session.delete('user'))
  @user.delete!
  flash "User #{@user.username} has been deleted."
  redirect '/'
end

# view a list of images
get '/images' do
  erb :images
end

# upload a new image
post '/images' do
  redirect_unless_authorized

  if params['image_upload'].nil?
    handle_error 422, 'Please select an image to upload.', :images
  else
    image = Image.upload params['image_upload']

    error ||= image.error
    if error
      handle_error 422, error, :images
    else
      image.save!
      flash "#{image.name} was uploaded."
      redirect '/images'
    end
  end
end

# view an image
get '/images/:image_name' do
  @image = Image.new params['image_name']
  erb :image
end

# delete an image
post '/images/:image_name/delete' do
  redirect_unless_authorized

  image = Image.new params['image_name']
  if image.exists?
    image.delete!
    flash "#{image.name} has been deleted."
  else
    flash "#{image.name} does not exist."
  end

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

  @document = Document.new params['document_name'], params['content']

  error = @document.name_error
  if error
    handle_error 422, error, :new
  else
    @document.save!
    flash "#{@document.name} was created."
    redirect '/'
  end
end

# view a document by name
get '/:document_name' do
  @document = Document.new params['document_name']

  if @document.exists?
    render_content @document
  else
    flash "#{@document.name} does not exist."
    redirect '/'
  end
end

# duplicate a document by name
post '/:document_name/duplicate' do
  redirect_unless_authorized

  document = Document.new params['document_name']
  copy = document.duplicate

  if copy.exists?
    flash "#{copy.name} already exists."
  else
    copy.save!
    flash "Duplicated #{document.name} as #{copy.name}."
  end

  redirect '/'
end

# render edit document form
get '/:document_name/edit' do
  redirect_unless_authorized

  @document = Document.new params['document_name']

  if @document.exists?
    erb :edit
  else
    flash "#{@document.name} does not exist."
    redirect '/'
  end
end

# edit a document by name
post '/:document_name' do
  redirect_unless_authorized

  @document = Document.new params['document_name'], params['content']

  if @document.exists?
    @document.save!
    flash "#{@document.name} has been updated."
  else
    flash "#{@document.name} does not exist."
  end

  redirect '/'
end

# delete a document
post '/:document_name/delete' do
  redirect_unless_authorized

  @document = Document.new params['document_name']

  if @document.exists?
    @document.delete!
    flash "#{@document.name} has been deleted."
  else
    flash "#{@document.name} does not exist."
  end

  redirect '/'
end

# view a list of document versions
get '/:document_name/versions' do
  @document = Document.new params['document_name']
  erb :versions
end

# view a specific version of a document
get '/:document_name/:version' do
  @document = Document.new params['document_name']
  @version = params['version']

  if @document.exists? @version
    headers['Content-Type'] = @document.content_type
    render_content @document, @version
  else
    flash "Version #{@version} of #{@document.name} does not exist."
    redirect '/'
  end
end

private

def flash(message)
  session['message'] = message
end

# true if user is signed in
def user?
  session.key? 'user'
end

def redirect_unless_authorized
  return if user?

  flash 'You must be signed in to do that.'
  redirect '/'
end

def handle_error(status_code, error_message, view_to_render)
  status status_code
  flash error_message
  erb view_to_render
end
