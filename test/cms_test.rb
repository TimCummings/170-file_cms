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
    FileUtils.mkdir_p data_path
  end

  def teardown
    FileUtils.rm_rf data_path
  end

  def create_document(file_name, contents = '')
    file_path = File.join(data_path, file_name)
    File.open(file_path, 'w') { |file| file.write(contents) }
  end

  def session
    last_request.env['rack.session']
  end

  def admin_session
    { 'rack.session' => { user: 'admin' } }
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

  def test_viewing_file_txt
    create_document 'about.txt', 'About Ruby'
    get '/about.txt'

    assert_equal 200, last_response.status 
    assert_equal 'text/plain', last_response['Content-Type'] 
    assert_includes last_response.body, 'About Ruby' 
  end

  def test_viewing_file_md
    create_document 'about.md', '# About Ruby'
    get '/about.md'

    assert_equal 200, last_response.status
    assert_equal 'text/html', last_response['Content-Type']
    assert_includes last_response.body, '<h1>About Ruby</h1>'
  end

  def test_viewing_nonexistent_file
    get '/not_a_file.txt'

    assert_equal 302, last_response.status
    assert_equal 'not_a_file.txt does not exist.', session['message']
  end

  def test_flash_messages_disappear_after_being_shown
    get '/not_a_file.txt'
    assert_equal 'not_a_file.txt does not exist.', session['message']
    get last_response['Location']
    assert_nil session['message']
  end

  def test_user_edit_form
    create_document 'about.md', '# About Ruby'

    get 'about.md/edit', {}, admin_session

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, "# About Ruby</textarea>"
    assert_includes last_response.body, '<button type="submit">Save Changes</button>'
  end

  def test_guest_edit_form
    create_document 'about.md', '# About Ruby'

    get 'about.md/edit'

    assert_equal 401, last_response.status
    assert_equal 'You must be signed in to do that.', session['message']

    get last_response['Location']

    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    refute_includes last_response.body, "About Ruby</textarea>"
    refute_includes last_response.body, '<button type="submit">Save Changes</button>'
  end

  def test_user_editing_a_file
    create_document 'about.md', '# About Ruby'

    post '/about.md', { content: 'Hello World!' }, admin_session

    assert_equal 302, last_response.status
    assert_equal 'about.md has been updated.', session['message']

    get last_response['Location']

    get '/about.md'

    assert_equal 200, last_response.status
    assert_equal 'text/html', last_response['Content-Type']
    assert_includes last_response.body, 'Hello World!'
  end

  def test_guest_editing_a_file
    create_document 'about.md', '# About Ruby'

    post '/about.md', content: 'Hello World!'

    assert_equal 401, last_response.status
    assert_equal 'You must be signed in to do that.', session['message']

    get last_response['Location']

    get '/about.md'

    assert_equal 200, last_response.status
    assert_equal 'text/html', last_response['Content-Type']
    assert_includes last_response.body, 'About Ruby'
    refute_includes last_response.body, 'Hello World!'
  end

  def test_user_new_file_form
    get '/new', {}, admin_session

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Add a new document:'
    assert_includes last_response.body, '<input type="text" name="file_name"'
    assert_includes last_response.body, '<button type="submit">Create</button>'
  end

  def test_guest_new_file_form
    get '/new'

    assert_equal 401, last_response.status
    assert_equal 'You must be signed in to do that.', session['message']

    get last_response['Location']

    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    refute_includes last_response.body, 'Add a new document:'
    refute_includes last_response.body, '<input type="text" name="file_name"'
    refute_includes last_response.body, '<button type="submit">Create</button>'
  end

  def test_user_creating_a_file
    post '/create', { file_name: 'new_file.txt' }, admin_session

    assert_equal 302, last_response.status
    assert_equal 'new_file.txt was created.', session['message']

    get last_response['Location']
    assert_includes last_response.body, 'new_file.txt</a>'
  end

  def test_guest_creating_a_file
    post '/create', file_name: 'new_file.txt'

    assert_equal 401, last_response.status
    assert_equal 'You must be signed in to do that.', session['message']

    get last_response['Location']

    refute_includes last_response.body, 'new_file.txt</a>'
  end

  def test_creating_a_file_without_a_name
    post '/create', { file_name: '' }, admin_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'A name is required.'
  end

  def test_delete_button_is_present_on_index
    create_document 'new_file.txt'
    get '/'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'new_file.txt</a>'
    assert_includes last_response.body, 'action="/new_file.txt/delete"'
  end

  def test_user_delete_a_file
    create_document 'new_file.txt'

    post '/new_file.txt/delete', {}, admin_session

    assert_equal 302, last_response.status
    assert_equal 'new_file.txt was deleted.', session['message']

    get last_response['Location']

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    refute_includes last_response.body, 'new_file.txt</a>'
    refute_includes last_response.body, 'action="/new_file.txt/delete"'
  end

  def test_guest_delete_a_file
    create_document 'new_file.txt'

    post '/new_file.txt/delete'

    assert_equal 401, last_response.status
    assert_equal 'You must be signed in to do that.', session['message']

    get last_response['Location']

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'new_file.txt</a>'
    assert_includes last_response.body, 'action="/new_file.txt/delete"'
  end

  def test_sign_in_button_is_present_on_index
    signin_button = <<~SIGNIN
      <form action="/users/signin" method="get">
          <button type="submit">Sign In</button>
    SIGNIN

    get '/'

    assert_equal 200, last_response.status
    assert_includes last_response.body, signin_button
  end

  def test_sign_in_form
    get '/users/signin'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, '<form action="/users/signin" method="post">'
    assert_includes last_response.body, '<input type="text" name="username"'
    assert_includes last_response.body, '<input type="password" name="password"'
    assert_includes last_response.body, '<button type="submit">Sign In</button>'
  end

  def test_valid_sign_in
    post '/users/signin', username: 'admin', password: 'secret'

    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session['message']
    assert_equal 'admin', session['user']

    get last_response['Location']

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Signed in as admin.'
    assert_includes last_response.body, '<form action="/users/signout" method="post">'
    assert_includes last_response.body, '<button type="submit">Sign Out</button>'
  end

  def test_invalid_sign_in
    post '/users/signin', username: 'invalid_user', password: 'wrong_password'

    assert_equal 401, last_response.status
    assert_nil session['user']
    assert_includes last_response.body, 'Invalid Credentials'
    assert_includes last_response.body, '<input type="text" name="username" id="username" value="invalid_user"'
  end

  def test_sign_out
    get '/', {}, admin_session
    assert_includes last_response.body, 'Signed in as admin'

    post '/users/signout'

    assert_equal 302, last_response.status
    assert_equal 'You have been signed out.', session['message']

    get last_response['Location']

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_nil session['user']

    signin_button = <<~SIGNIN
      <form action="/users/signin" method="get">
          <button type="submit">Sign In</button>
    SIGNIN

    assert_includes last_response.body, signin_button
  end
end
