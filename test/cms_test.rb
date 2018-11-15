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

  def setup
    FileUtils.mkdir data_path
  end

  def teardown
    FileUtils.rm_rf data_path
  end

  def create_document(file_name, contents = '')
    file_path = File.join(data_path, file_name)
    File.open(file_path, 'w') { |file| file.write(contents) }
  end

  def test_index
    create_document 'about.md'
    create_document 'changes.txt'

    get '/'

    assert_equal 200, last_response.status 
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type'] 
    assert_includes last_response.body, 'about.md</a>'
    assert_includes last_response.body, 'changes.txt</a>' 
  end

  def test_file_name_txt
    content = <<~ABOUT
      About Ruby
      Wondering why Ruby is so popular?
      Its fans call it a beautiful, artful language. And yet, they say it's handy and practical.
      What gives?
    ABOUT

    create_document 'about.txt', content
    get '/about.txt'

    assert_equal 200, last_response.status 
    assert_equal 'text/plain', last_response['Content-Type'] 
    assert_includes last_response.body, 'About Ruby' 
  end

  def test_bad_file_name
    get '/not_a_file.txt'

    assert_equal 302, last_response.status

    get last_response['Location']

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'not_a_file.txt does not exist.'

    get '/'
    refute_includes last_response.body, 'not_a_file.txt does not exist.'
  end

  def test_file_name_md
    content = <<~ABOUT
      # About Ruby
      Wondering why Ruby is so popular? Its fans call it a beautiful, artful language. And yet, they say it's handy and practical. What gives?
    ABOUT
    create_document('about.md', content)

    get '/about.md'

    assert_equal 200, last_response.status
    assert_equal 'text/html', last_response['Content-Type']
    assert_includes last_response.body, '<h1>About Ruby</h1>'
  end

  def test_edit_form
    content = <<~ABOUT
      # About Ruby
      Wondering why Ruby is so popular?
      Its fans call it a beautiful, artful language. And yet, they say it's handy and practical.
      What gives?
    ABOUT
    create_document('about.md', content)

    get 'about.md/edit'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, "What gives?\n</textarea>"
    assert_includes last_response.body, '<button type="submit">Save Changes</button>'
  end

  def test_editing_a_file
    content = <<~ABOUT
      # About Ruby
      Wondering why Ruby is so popular?
      Its fans call it a beautiful, artful language. And yet, they say it's handy and practical.
      What gives?
    ABOUT
    create_document('about.md', content)

    post '/about.md', 'content' => 'Hello World!'

    assert_equal 302, last_response.status
    get last_response['Location']

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'about.md has been updated.'

    get '/about.md'

    assert_equal 200, last_response.status
    assert_equal 'text/html', last_response['Content-Type']
    assert_includes last_response.body, 'Hello World!'
  end

  def test_new_file_form
    get '/new'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Add a new document:'
    assert_includes last_response.body, '<input type="text" name="file_name"'
    assert_includes last_response.body, '<button type="submit">Create</button>'
  end

  def test_creating_a_file
    post '/create', 'file_name' => 'new_file.txt'

    assert_equal 302, last_response.status
    get last_response['Location']

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'new_file.txt was created.'
  end

  def test_creating_a_file_without_a_name
    post '/create', 'file_name' => ''

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'A name is required.'
  end
end
