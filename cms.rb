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
  File.expand_path('..', __FILE__)
end

def data_path
  root + '/data/'
end

def load_content(file_path)
  content = File.read(file_path)
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

# index: view a list of files
get '/' do
  @files = Dir.glob(data_path + '*').map { |path| File.basename(path) }
  erb :index
end

# view a file by name
get '/:file_name' do
  @file_name = params['file_name']
  file_path = data_path + @file_name

  if File.file?(file_path)
    load_content(file_path)
  else
    session['message'] = "#{@file_name} does not exist."
    redirect '/'
  end
end

# render edit file form
get '/:file_name/edit' do
  @file_name = params['file_name']
  file_path = data_path + @file_name

  if File.file?(file_path)
    @content = File.read(file_path)
    erb :edit
  else
    session['message'] = "#{@file_name} does not exist."
    redirect '/'
  end
end

# edit a file by name
post '/:file_name' do
  @file_name = params['file_name']
  file_path = data_path + @file_name
  @content = params['content']

  if File.file?(file_path)
    File.write(file_path, @content)

    session['message'] = "#{@file_name} has been updated."
  else
    session['message'] = "#{@file_name} does not exist."
  end

  redirect '/'
end
