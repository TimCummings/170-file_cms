# cms_test.rb

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/reporters'
require 'rack/test'

Minitest::Reporters.use!

require_relative '../cms'

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get '/'

    assert_equal 200, last_response.status 
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type'] 
    assert_includes last_response.body, 'about.txt</a>' 
    assert_includes last_response.body, 'changes.txt</a>' 
    assert_includes last_response.body, 'history.txt</a>' 
  end

  def test_good_file_name
    get '/about.txt'

    assert_equal 200, last_response.status 
    assert_equal 'text/plain', last_response['Content-Type'] 
    assert_includes last_response.body, 'About Ruby' 
  end

  def test_bad_file_name
    get '/not_a_file.txt'

    assert_equal 404, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Could not find file `not_a_file.txt`.'
  end
end
