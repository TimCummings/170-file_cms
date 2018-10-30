# cms.rb

require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

def data_path
  File.expand_path('..', __FILE__)
end

get '/' do
  @files = Dir.glob(data_path + '/data/*').map { |path| File.basename(path) }
  erb :index
end
