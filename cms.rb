# cms.rb

require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

EXT_TYPE = {
  '.txt' => 'text/plain'
}

def data_path
  File.expand_path('..', __FILE__)
end

get '/' do
  @files = Dir.glob(data_path + '/data/*').map { |path| File.basename(path) }
  erb :index
end

get '/:file_name' do
  @file_name = params['file_name']
  file_path = data_path + '/data/' + @file_name

  if File.file?(file_path)
    headers['Content-Type'] = EXT_TYPE[File.extname(@file_name)]
    File.read(file_path)
  else
    session['error'] = "#{@file_name} does not exist."
    redirect '/'
  end
end
