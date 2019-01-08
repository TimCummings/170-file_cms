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
    FileUtils.mkdir_p images_path
  end

  def teardown
    FileUtils.rm_rf data_path
    FileUtils.rm_rf images_path
  end

  def create_document(document_name, content = '')
    document_path = File.join(data_path, document_name)
    FileUtils.mkdir document_path

    initial_version = File.join(document_path, '1')
    File.open(initial_version, 'w') { |file| file.write(content) }
  end

  def session
    last_request.env['rack.session']
  end

  def admin_session
    { 'rack.session' => { user: 'test_user' } }
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

  def test_viewing_document_txt
    create_document 'about.txt', 'About Ruby'
    get '/about.txt'

    assert_equal 200, last_response.status 
    assert_equal 'text/plain', last_response['Content-Type'] 
    assert_includes last_response.body, 'About Ruby' 
  end

  def test_viewing_document_md
    create_document 'about.md', '# About Ruby'
    get '/about.md'

    assert_equal 200, last_response.status
    assert_equal 'text/html', last_response['Content-Type']
    assert_includes last_response.body, '<h1>About Ruby</h1>'
  end

  def test_viewing_nonexistent_document
    get '/not_a_document.txt'

    assert_equal 302, last_response.status
    assert_equal 'not_a_document.txt does not exist.', session['message']
  end

  def test_flash_messages_disappear_after_being_shown
    get '/not_a_document.txt'
    assert_equal 'not_a_document.txt does not exist.', session['message']
    get last_response['Location']
    assert_nil session['message']
  end

  def test_user_duplicating_a_document
    create_document 'about.md', '# About Ruby'

    post '/about.md/duplicate', {}, admin_session

    assert_equal 302, last_response.status
    assert_equal 'Duplicated about.md as about-copy.md.', session['message']

    get last_response['Location']
    assert_includes last_response.body, 'about-copy.md</a>'

    get '/about-copy.md'

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<h1>About Ruby</h1>'
  end

  def test_guest_duplicating_a_document
    create_document 'about.md', '# About Ruby'

    post '/about.md/duplicate'

    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session['message']

    get last_response['Location']
    refute_includes last_response.body, 'about-copy.md</a>'
  end

  def test_duplicating_already_duplicated_document
    create_document 'about.md', '# About Ruby'

    post '/about.md/duplicate', {}, admin_session

    post '/about.md/duplicate'

    assert_equal 302, last_response.status
    assert_equal 'about-copy.md already exists.', session['message']
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

    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session['message']

    get last_response['Location']

    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    refute_includes last_response.body, "About Ruby</textarea>"
    refute_includes last_response.body, '<button type="submit">Save Changes</button>'
  end

  def test_user_editing_a_document
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

  def test_guest_editing_a_document
    create_document 'about.md', '# About Ruby'

    post '/about.md', content: 'Hello World!'

    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session['message']

    get '/about.md'

    assert_equal 200, last_response.status
    assert_equal 'text/html', last_response['Content-Type']
    assert_includes last_response.body, 'About Ruby'
    refute_includes last_response.body, 'Hello World!'
  end

  def test_user_new_document_form
    get '/new', {}, admin_session

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Add a new document:'
    assert_includes last_response.body, '<input type="text" name="document_name"'
    assert_includes last_response.body, '<button type="submit">Create</button>'
  end

  def test_guest_new_document_form
    get '/new'

    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session['message']

    get last_response['Location']

    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    refute_includes last_response.body, 'Add a new document:'
    refute_includes last_response.body, '<input type="text" name="document_name"'
    refute_includes last_response.body, '<button type="submit">Create</button>'
  end

  def test_user_creating_a_document
    post '/create', { document_name: 'new_document.txt' }, admin_session

    assert_equal 302, last_response.status
    assert_equal 'new_document.txt was created.', session['message']

    get last_response['Location']
    assert_includes last_response.body, 'new_document.txt</a>'
  end

  def test_guest_creating_a_document
    post '/create', document_name: 'new_document.txt'

    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session['message']

    get last_response['Location']

    refute_includes last_response.body, 'new_document.txt</a>'
  end

  def test_creating_a_document_without_a_name
    post '/create', { document_name: '' }, admin_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'A name is required.'
  end

  def test_creating_a_duplicate_document
    post '/create', { document_name: 'scratch.txt' }, admin_session

    post '/create', { document_name: 'scratch.txt' }, admin_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'scratch.txt already exists.'
  end

  def test_creating_a_document_without_an_extension
    post '/create', { document_name: 'scratch' }, admin_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'A valid document extension is required (e.g. .txt).'
  end

  def test_creating_a_document_with_unsupported_extension
    post '/create', { document_name: 'scratch.pdf' }, admin_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, '.pdf extension is not currently supported.'
  end

  def test_delete_button_is_present_on_index
    create_document 'new_document.txt'
    get '/'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'new_document.txt</a>'
    assert_includes last_response.body, 'action="/new_document.txt/delete"'
  end

  def test_user_delete_a_document
    create_document 'new_document.txt'

    post '/new_document.txt/delete', {}, admin_session

    assert_equal 302, last_response.status
    assert_equal 'new_document.txt was deleted.', session['message']

    get last_response['Location']

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    refute_includes last_response.body, 'new_document.txt</a>'
    refute_includes last_response.body, 'action="/new_document.txt/delete"'
  end

  def test_guest_delete_a_document
    create_document 'new_document.txt'

    post '/new_document.txt/delete'

    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session['message']

    get last_response['Location']

    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'new_document.txt</a>'
    assert_includes last_response.body, 'action="/new_document.txt/delete"'
  end

  def test_versions_view
    create_document 'new_document.txt'
    post '/new_document.txt', { content: 'Hello World!' }, admin_session

    get '/new_document.txt/versions'

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<li><a href="/new_document.txt/2">2</a></li>'
    assert_includes last_response.body, '<li><a href="/new_document.txt/1">1</a></li>'
  end

  def test_viewing_old_version
    create_document 'new_document.txt'
    post '/new_document.txt', { content: 'Hello World!' }, admin_session
    post '/new_document.txt', { content: 'Goodbye.' }, admin_session

    get '/new_document.txt/2'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Hello World!'
    refute_includes last_response.body, 'Goodbye.'
  end

  def test_viewing_nonexistant_version
    create_document 'new_document.txt'
    post 'new_document.txt', { content: 'Hello World!' }, admin_session

    get '/new_document.txt/3'

    assert_equal 302, last_response.status
    assert_equal 'Version 3 of new_document.txt does not exist.', session['message']
  end

  def test_sign_in_button_is_present_on_index
    signin_button = <<~SIGNIN
      <form method="get" action="/users/signin">
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
    assert_includes last_response.body, '<form method="post" action="/users/signin">'
    assert_includes last_response.body, '<input type="text" name="username"'
    assert_includes last_response.body, '<input type="password" name="password"'
    assert_includes last_response.body, '<button type="submit">Sign In</button>'
  end

  def test_valid_sign_in
    post '/users/signin', username: 'test_user', password: 'opensesame'

    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session['message']
    assert_equal 'test_user', session['user']

    get last_response['Location']

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Signed in as test_user.'
    assert_includes last_response.body, '<form method="post" action="/users/signout">'
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
    assert_includes last_response.body, 'Signed in as test_user'

    post '/users/signout'

    assert_equal 302, last_response.status
    assert_equal 'You have been signed out.', session['message']

    get last_response['Location']

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_nil session['user']

    signin_button = <<~SIGNIN
      <form method="get" action="/users/signin">
          <button type="submit">Sign In</button>
    SIGNIN

    assert_includes last_response.body, signin_button
  end

  def test_create_new_user
    post '/users', new_username: 'temp_user', new_password: 'temppass', confirm_new_password: 'temppass'

    assert_equal 302, last_response.status
    assert_equal 'temp_user', session['user']

    post '/users/signout'

    assert_equal 302, last_response.status
    assert_nil session['user']

    post '/users/signin', username: 'temp_user', password: 'temppass'

    assert_equal 302, last_response.status
    assert_equal 'temp_user', session['user']

    delete_user('temp_user')
  end

  def test_create_new_user_with_empty_name
    post '/users'

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'A new username is required.'
  end

  def test_create_new_user_with_whitespace_name
    post '/users', new_username: '         '

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'A new username is required.'
  end

  def test_create_new_user_with_empty_password
    post '/users', new_username: 'buggy_user'

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'A new password is required.'
  end

  def test_create_new_user_with_empty_confirm_password
    post '/users', new_username: 'buggy_user', new_password: 'youwillneverguess'

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'New password must be confirmed.'
  end

  def test_create_new_user_with_mismatched_passwords
    post '/users', new_username: 'buggy_user', new_password: 'match', confirm_new_password: 'notamatch'

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Passwords don't match."
  end

  def test_create_duplicate_user
    post '/users', new_username: 'temp_user', new_password: 'temppass', confirm_new_password: 'temppass'

    assert_equal 302, last_response.status
    assert_equal 'temp_user', session['user']

    post '/users/signout'

    assert_equal 302, last_response.status
    assert_nil session['user']

    post '/users', new_username: 'temp_user', new_password: 'temppass', confirm_new_password: 'temppass'

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'User temp_user already exists.'

    delete_user('temp_user')
  end

  def test_delete_user
    post '/users', new_username: 'temp_user', new_password: 'temppass', confirm_new_password: 'temppass'

    assert_equal 302, last_response.status
    assert_equal 'temp_user', session['user']

    post '/users/delete'

    assert_equal 302, last_response.status
    assert_nil session['user']
    assert_equal 'User temp_user has been deleted.', session['message']

    post '/users/signin', username: 'temp_user', password: 'temppass'

    assert_equal 401, last_response.status
    assert_includes last_response.body, 'Invalid Credentials'
  end

  def test_user_upload_image
    post '/images', { image_upload: Rack::Test::UploadedFile.new(build_path('test_image.jpg')) }, admin_session

    assert_equal 302, last_response.status
    assert_equal 'test_image.jpg was uploaded.', session['message']

    get last_response['Location']

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'test_image.jpg</a>'
  end

  def test_guest_upload_image
    post '/images', { image_upload: Rack::Test::UploadedFile.new(build_path('test_image.jpg')) }

    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session['message']
  end

  def test_user_delete_image
    post '/images', { image_upload: Rack::Test::UploadedFile.new(build_path('test_image.jpg')) }, admin_session

    assert_equal 302, last_response.status
    assert_equal 'test_image.jpg was uploaded.', session['message']

    get last_response['Location']

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'test_image.jpg</a>'

    post '/images/test_image.jpg/delete', {}, admin_session
    assert_equal 302, last_response.status
    assert_equal 'test_image.jpg was deleted.', session['message']

    get last_response['Location']

    assert_equal 200, last_response.status
    refute_includes last_response.body, 'test_image.jpg</a>'
  end

  def test_guest_delete_image
    post '/images', { image_upload: Rack::Test::UploadedFile.new(build_path('test_image.jpg')) }, admin_session

    assert_equal 302, last_response.status
    assert_equal 'test_image.jpg was uploaded.', session['message']

    get last_response['Location']

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'test_image.jpg</a>'

    post '/users/signout'

    assert_equal 302, last_response.status
    assert_equal 'You have been signed out.', session['message']

    post '/images/test_image.jpg/delete'

    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session['message']
  end
end
