# cms.rb

require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

get '/' do
  'Getting started.'
end
