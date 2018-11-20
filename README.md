
[comment]: # (README.md)

# 170 Project: File-Based CMS

### Introduction 10/29/2018

The goal of this project is to build a simple file-based content management system. This project uses a new format that presents each assignment in three parts: a list of requirements, a list of implementation details, and an example solution that takes the requirements and implementation details into account.

The **Requirements** are written as they might be if you were working on a project with a client or project designer. They are high-level, presented from a user's perspective, and will typically be devoid of any technical information.

As you move through each assignment, first read through the requirements and think about _what_ the application needs to do in order to satisfy the requirements. Next, think about _how_ the software will accomplish these things and what changes you need to make to it so that it can.

> Some of the assignments will contain **Hints**. They are there to help keep you on track, so don't hesitate to look at them after coming up with a plan on your own.

Once you have a plan in mind and you're fairly confident in it, you can start making the changes you identified needed to be made. Each assignment also includes an **Implementation** section with a list of concrete steps that need to be completed in order to fulfill the assignment's requirements. Feel free to use the Implementation section as a reference, but it is important that you come up with a plan before looking at the steps we've provided.

Finally, each assignment has a **Solution**, which is an example solution based on the Requirements and Implementation sections. It is OK if your solution is different than the one that is supplied as long as you can describe _how_ they are different and if there will be any noticeable difference to a user.

Partway through the project, we'll start looking at writing tests for Sinatra applications. At that point, **Solution** will also contain a set of tests that are relevant to the current assignment. It's a good idea to think about what the tests should be doing and trying to write them yourself before comparing your tests to the example tests and moving on to write and verify the rest of the solution.

As you work through the project, focus on and complete each set of requirements before moving on to the next set.

> **This Project is Incompatible with Heroku**
> 
> This project uses the filesystem to persist data, and as a result, it isn't a good fit for Heroku. Applications running on Heroku [only have access to an ephemeral filesystem](https://devcenter.heroku.com/articles/dynos#ephemeral-filesystem). This means any files that are written by a program will be lost each time the application goes to sleep, is redeployed, or restarts (which typically happens every 24 hours).
> 
> This project will, however, run just fine within your development environment as you work through the lesson. Using the filesystem to persist data in this project provides an opportunity to focus on the fundamentals of web development while gaining some experience with the Ruby File and IO classes.
> 
> The use of files on the filesystem to persist data works fine for small projects, but in most production applications, using an external datastore such as a database is usually a better idea. We'll work more with databases in later courses.

---

### Getting Started - 10/29/2018

In this assignment, we'll set up the project and add a placeholder route to make sure everything is ready for the rest of the project.

**Requirements**

When a user visits the path "/", the application should display the text "Getting started."

**Implementation**

* Setup basic structure for a Sinatra web application:
  * `Gemfile` with dependencies
  * App file with a root route (`get "/"`)
* `bundle install`

---

### Adding an Index Page - 10/29/2018

Many content management systems store their content in databases, but some use files stored on the filesystem instead. This is the path we will follow with this project. Each document within the CMS will have a name that includes an extension. This extension will determine how the contents of the page are displayed in later steps.

**Requirements**

When a user visits the home page, they should see a list of the documents in the CMS: `history.txt`, `changes.txt` and `about.txt`.

**Implementation**

* setup the directory structure with the specified files in a `public` directory
* create a `views` directory and add an `index.erb` view that lists the files
* redirect the root route to the `index.erb` view

**Corrections Based on Provided Implementation/Solution**

* no need to redirect `/` to `/index`, just display `index` view from `/`
* use a `data` directory, not `public`
* observe more consistent naming conventions ("files" rather than "documents")

---

### Viewing Text Files - 10/29/2018

This is a good time to add some content to the files in the `data` directory of the project. Feel free to use any text you'd like.

**Requirements**

1. When a user visits the index page, they are presented with a list of links, one for each document in the CMS.
2. When a user clicks on a document link in the index, they should be taken to a page that displays the content of the file whose name was clicked.
3. When a user visits the path `/history.txt`, they will be presented with the content of the document `history.txt`.
4. The browser should render a text file as a plain text file.

**Implementation**

* Populate `data` files with content.
* create a route for viewing a specific file by name
* have the list of files on `index` link to each file via this route
* create a view to display the contents of a specific file by name
* use `Content-Type` header to display a file's contents appropriately

**Corrections Based on Provided Implementation/Solution**
* no need for a `file` view template, just render file contents directly

---

### Adding Tests - 10/30/2018

**Requirements**

* Write tests for the routes that the application already supports.

**Implementation**

* update `Gemfile` with testing dependencies
* `bundle install`
* create a `test` directory with a file to test the app
  * set testing env variable
  * require files for testing
  * create test class including `app` method
* for each route in the app:
  * make a request
  * access the response
  * assert against response values

---

### Handling Requests for Nonexistent Documents - 11/3/2018

We aren't focusing too much on testing techniques or philosophy in this course, but it is still a good idea to start thinking about what kind of tests you'd need to write to verify the behavior of an application as it changes.

Try to write a test for this assignment by describing exactly what the user does (shown below under **Requirements**). The solution for the test is shown separately below if you'd like to see it without seeing the rest of the implementation.

> You can make more than one request in a `Rack::Test` test.

**Requirements**

* When a user attempts to view a document that does not exist, they should be redirected to the index page and shown the message: `$DOCUMENT does not exist.`
* When the user reloads the index page after seeing an error message, the message should go away.

**Implementation**

* enable session
* modify the `/:file_name` route to:
  * set an error flash message via the session if the requested file is not found
  * redirect to the index page
* modify the `index` view to display flash messages
  * process a flash message message by deleting it from the session so it goes away on page reload
* modify `bad_file_name_test` to:
  * verify the redirect from the first response
  * follow the redirect
  * verify the flash message of the second response

---

### Viewing Markdown Files - 11/3/2018

Markdown is a common text-to-html markup language. You've probably encountered it here on Launch School, on Stack Overflow, GitHub, and other popular sites already.

Converting raw Markdown text into HTML can be done with a variety of libraries, many of which are available for use with a Ruby application. We recommend you use [Redcarpet](https://github.com/vmg/redcarpet) in this project. To get started, follow these steps:

1. Add `redcarpet` to your `Gemfile` and run `bundle install`.
2. Add `require "redcarpet"` to the top of your application.
3. To actually render text into HTML, create a `Redcarpet::Markdown` instance and then use it to process the text:

```ruby
markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
markdown.render("# This will be a headline!")
```

You can read more about how to use Redcarpet [on GitHub](https://github.com/vmg/redcarpet).

**Requirements**

* When a user views a document written in Markdown format, the browser should render the rendered HTML version of the document's content.

**Implementation**

* install and require `redcarpet` as specified
* create a markdown file in the `data` directory
* add logic to the `/:file_name` route to detect markdown files and render them via `redcarpet`
* add a test for a markdown file

**Corrections based on provided Implementation/Solution**

* extract markdown rendering to a method
* extract file handling (determining content type and loading contents) to a method

---

### Editing Document Content - 11/4/2018

Now it’s time to allow users to modify the content stored within our CMS.

**Requirements**

1. When a user views the index page, they should see an “Edit” link next to each document name.
2. When a user clicks an edit link, they should be taken to an edit page for the appropriate document.
3. When a user views the edit page for a document, that document's content should appear within a textarea.
4. When a user edits the document's content and clicks a “Save Changes” button, they are redirected to the index page and are shown a message: `$FILENAME has been updated.`.

**Implementation**

* modify `index` view to show an "Edit" link next to each file
* add a route for editing a file:
  * `get '/:file_name/edit'`
  * `post '/:file_name'`
* add a view for editing a file
  * file contents should appear in a `textarea`
* add a `post` route for saving changes; it should set a flash message and redirect to `index`

**Corrections based on provided Implementation/Solution**
* in `edit` form test, also check for presence of submit button
* in `post` `edit` route, shorten file write using `File` class method instead of instance method

---

### Isolating Test Execution - 11/7/2018

Right now the application is using the same data during both development and testing. This means that as we modify the data as we continue development, there is a chance we break some of the tests we've already written. To see this for yourself, edit the file `about.md` and change the first line. One of the tests will start to fail.

The technique used to avoid this involves using a different set of data for each _environment_ the application will run in. We currently have two active environments: development and test. If we were using a database, we could use different databases. Since our data is stored entirely on the filesystem, though, we can simply use two different directories to hold the data for our two environments.

Furthermore, if we think back to the [SEAT Approach](https://launchschool.com/lessons/dd2ae827/assignments/3814), what we _really_ should be doing is setting up the data for each test in the **set up** step, and then deleting it in the **tear down** step. Here is a review of the SEAT approach:

1. Set up the necessary objects.
2. Execute the code against the object we're testing.
3. Assert the results of the execution.
4. Tear down and clean up any lingering artifacts.

So far, our tests have only been doing #2 and #3, which is fine in cases where there isn't any set up or tear down needed. In the case of this application, though, it would be advantageous to start using those steps to prepare for and clean up after our tests run.

The first thing we need to be able to do is select a directory for data based on the environment the code is running in. If we look through our code, we'll see that we're referencing the `root` local variable in nearly all of the routes, and when we use it, we're always appending `/data` to it. So let's rework the code to have a method called `data_path` that returns the correct path to where the documents will be stored based on the current environment.

Then, we can replace the usage of the `root` variable with references to `data_path`. While we're doing that, we can use `File.join` to combine path segments instead of doing it ourselves manually. The main benefit afforded by `File.join` is it will use the correct path separator based on the current operating system, which will be `/` on OS X and Linux and `\`` on Windows.

Now that we've done that, a bunch of the project's tests will be failing since there is now no data in the system when they run. We can use the `setup` method in our test to create the `data` directory if it doesn't exist and the `teardown` method to delete it. These methods are called by Minitest before and after **every** test. This means each test will now be run in an isolated environment.

Note that within `test/cms_test.rb` we are able to access the `data_path` method defined in `cms.rb` because it is defined in a global scope.

> The [FileUtils](http://ruby-doc.org/stdlib-2.3.0/libdoc/fileutils/rdoc/FileUtils.html) module contains a variety of useful methods for working with files and paths. The names and functionality of the methods provided by this module are based on the names and options of common shell commands.

We'll need one more piece to finish this refactoring, and that is to provide a simple way to create documents during testing. This method creates empty files by default, but an optional second parameter allows the contents of the file to be passed in.

---

### Adding Global Style and Behavior - 11/8/2018

When a message is displayed to a user anywhere on the site, it should be styled in a way that is easily distinguished from the rest of the page. This will help attract the user's attention to the information in the message that would otherwise be easy to miss.

While we're adding styling, we can also change the default display of the site to use a sans-serif font and have a little padding around the outside.

**Requirements**

1. When a message is displayed to a user, that message should appear against a yellow background.
2. Messages should disappear if the page they appear on is reloaded.
3. Text files should continue to be displayed by the browser as plain text.
4. The entire site (including markdown files, but not text files) should be displayed in a sans-serif typeface.

**Implementation**

* create a stylesheet to apply styles to the application; link the stylesheet in `layout.erb`
  * create a `flash` class with a yellow background color and apply it to the flash message in `layout.erb`
  * use a `body` selector to:
    * apply `sans-serif` `font-family`
    * add padding
* disappearing flash messages on reload has already been implemented
* displaying text files as plain text has already been implemented

**Corrections based on provided Implementation/Solution**

* flash message background color is slightly different from picked value
* add `type="text/css"` to stylesheet links

---

### Sidebar: Favicon Requests - 11/8/2018

While working on this assignment you might start to notice messages such as: `favicon.ico does not exist.`

Save [this image](https://da77jsbdz4r05.cloudfront.net/images/file_based_cms/favicon.ico) to the project's `public` directory, and these errors will go away. Browsers automatically request a file called `favicon.ico` when they load sites so they can show an icon for that site. By adding this file, the browser will show it in the page's tab and your application won't have to deal with ignoring those requests, as they can sometimes cause unexpected errors.

---

### Creating New Documents - 11/14/2018

**Requirements**

1. When a user views the index page, they should see a link that says "New Document".
2. When a user clicks the "New Document" link, they should be taken to a page with a text input labeled "Add a new document:" and a submit button labeled "Create".
3. When a user enters a document name and clicks "Create", they should be redirected to the index page. The name they entered in the form should now appear in the file list. They should see a message that says "$FILENAME was created.", where $FILENAME is the name of the document just created.
4. If a user attempts to create a new document without a name, the form should be re-displayed and a message should say "A name is required."

**Implementation**

* Update the `index.erb` view to also display a `"New Document"` link.
* Create a `get '/new'` route to display a new document form.
* Create a `new.erb` view to display the new document form as specified.
* Create a `post '/'` route to create a new document.
  * If no name is provided, set the specified session message and re-render the new document form.
  * Otherwise, create the file, set the specified session message, and redirect to the index page.

**Corrections based on provided Implementation/Solution**
* Set a correct status code when re-rendering the new document form (due to no name provided.)
  * use 422, not 400
* For the new document route, don't post directly to index; use something semantic, e.g. `'/create'`

**Questions**
1. What will happen if a user creates a document without a file extension? How could this be handled?

> I make use of `FileUtils.touch`, so a document without a file extension would create ~~a directory~~ an extensionless file as below.

> Using `File.write` as the provided solution does will create the extensionless file, which our CMS will not know how to render. We could attempt to render it as plain text by default; but the better solution is to validate that a file extension is provided.

---

### Deleting Documents - 11/15/2018

**Requirements**

1. When a user views the index page, they should see a "delete" button next to each document.

2. When a user clicks a "delete" button, the application should delete the appropriate document and display a message: "$FILENAME was deleted".

**Implementation**

* Update `index.erb` to display a `delete` button next to each document.
* Create a `post '/:file_name/delete'` route.
  * set a session message as specified
  * delete the file
  * redirect to index

---

### Signing In and Out - 11/15/2018

Now that the content in our CMS can be modified and new documents can be created and deleted, we'd like to only allow registered users to be able to perform these tasks. To do that, though, first we'll need to have a way for users to sign in and out of the application.

**Requirements**

1. When a signed-out user views the index page of the site, they should see a "Sign In" button.
2. When a user clicks the "Sign In" button, they should be taken to a new page with a sign in form. The form should contain a text input labeled "Username" and a password input labeled "Password". The form should also contain a submit button labeled "Sign In"
3. When a user enters the username "admin" and password "secret" into the sign in form and clicks the "Sign In" button, they should be signed in and redirected to the index page. A message should display that says "Welcome!"
4. When a user enters any other username and password into the sign in form and clicks the "Sign In" button, the sign in form should be redisplayed and an error message "Invalid Credentials" should be shown. The username they entered into the form should appear in the username input.
5. When a signed-in user views the index page, they should see a message at the bottom of the page that says "Signed in as $USERNAME.", followed by a button labeled "Sign Out".
6. When a signed-in user clicks this "Sign Out" button, they should be signed out of the application and redirected to the index page of the site. They should see a message that says "You have been signed out.".

**Implementation**

* Add a method to verify if the user is signed in or not.
  * Check for a signed in user by seeing if there is a value in the session for the key `user`.
* Update the `index.erb` view to:
  * Display a `Sign In` button if the user is not signed in.
  * Display the specified "signed in as..." message with a `Sign Out` button if the user is signed in.
* Create a `signin.erb` view as specified.
* Create a `get '/users/signin'` route to display the signin view.
* Create a `post '/users/signin'` route that verifies the provided username and password.
  * If valid:
    * Sign the user in by setting `session['user']` to the username (`admin` for now).
    * Set a `'Welcome!'` flash message.
    * Redirect to index.
  * If invalid:
    * Set an `'Invalid Credentials'` flash message.
    * Re-render the `Sign In` view (a previously entered username should persist in the re-rendered form.)
* Create a `post '/users/signout'` route that:
  * Signs the user out by deleting the `user` key from the session.
  * Sets the specified flash message.
  * Redirects to index.

---

### Accessing the Session While Testing - 11/16/2018

Accessing the session from within tests is a little bit more involved than accessing the response's status, headers, or body. Just as `Rack::Test` makes the last response available as `last_response`, it makes the last request accessible within tests using `last_request`. We don't usually need to interact with the `MockRequest` object this method returns, but in the case of sessions, we need to.

Requests and responses in Rack are associated with a large Hash of data related to a request-response pair, called the "env" by Rack internally. Some of the values in this hash are used by frameworks such as Sinatra and Rails to access the path, parameters, and other attributes of the request. The session implementation used by Sinatra is actually supplied by Rack, and as a result the session object also lives in this Hash. To access it within a test, we can use `last_request.env`. Note that the `last_request` method is used here and **not** `last_response`.

> More info about `request.env` (known as the Rack Environment) can be found in the [specification for Rack](http://www.rubydoc.info/github/rack/rack/master/file/SPEC).

To get at the session object and its values, we can use `last_request.env["rack.session"]`. It's a good idea to use a helper method such as this one in your tests so that the session can be referenced using just `session`:

```ruby
def session
  last_request.env["rack.session"]
end
```

Now, within a test, you can make assertions about the values within a session:

```ruby
def test_sets_session_value
  get "/path_that_sets_session_value"
  assert_equal "expected value", session[:key]
end
```

If you need to go the other way (set a value in the session _before_ a request is made), `Rack::Test` allows values for the `Rack.env` hash to be provided to calls to `get` and `post` within a test. So a simple request like this one:

```ruby
def test_index
  get "/"
end
```

becomes this:

```ruby
def test_index_as_signed_in_user
  get "/", {}, {"rack.session" => { username: "admin"} }
end
```

There are two Hashes passed as arguments to `get`; the first is the Hash of parameters (which in this case is empty), and the second is values to be added to the request's `Rack.env` hash.

Once values have been provided like this once, they will be remembered for all future calls to `get` or `post` within the same test, _unless_, of course, those values are modified by code within your application. This means that you can set values for the session in the first request made in a test and they will be retained until you remove them.

**Implementation** (provided)

Update all existing tests to use the above methods for verifying session values. This means that many tests will become shorter as assertions can be made directly about the session instead of the content of a response's body. Specifically, instead of loading a page using `get` and then checking to see if a given message is displayed on it, `session[:message]` can be used to access the session value directly.

---

### Restricting Actions to Only Signed-in Users - 11/17/2018

Adding the concept of signed-in users to this project allows the ability to restrict certain actions (those that result in changes to data) to only those signed-in users. This is a very common model in web applications, where guest (signed-out) users can access resources but not make any changes to them.

> Sinatra's `redirect` method has some behavior that is not obvious from [the documentation](http://www.sinatrarb.com/intro.html#Browser%20Redirect) but will be useful in this assignment: it aborts handling of the current request. This means that in the following code:

```ruby
get "/" do
  redirect "/lists"
  erb :home
end
```

> `erb :home` is never executed because the `redirect` call terminates the request handling early. This is convenient because it means that redirecting can be used to short-circuit the logic within a route or helper. It does, however, violate the way that routes work otherwise, which is that their return value is what is sent back to the client.
>
> Internally, `redirect` calls `halt`, which is the method that actually aborts the request handling. You can read more about `halt` [in the documentation](http://www.sinatrarb.com/intro.html#Halting) and in [this blog post](http://myronmars.to/n/dev-blog/2012/01/why-sinatras-halt-is-awesome).

There are two ways to "sign in" a user within a test. The first is to sign in using the sign in form, and then test functionality that requires a user to be signed in:

```ruby
def test_editing_document
  # Submit the sign in form
  post "/users/signin", username: "admin", password: "secret"

  # Verify the user is signed in
  assert_equal "admin", session[:username]

  # Then, test something that required being signed in
  get "/changes.txt/edit"

  assert_equal 200, last_response.status
end
```

This works fine early in a project, when things are simple and there aren't a lot of tests. But if the sign in process ever changes, it will break a bunch of tests that are only using the sign-in functionality of the site to get a signed in user that can then be used to test some other part of the application. There are a couple ways to address this. The most obvious is to put the sign-in code within a method, and call it from within other tests:

```ruby
def sign_in_user
  # Submit the sign in form
  post "/users/signin", username: "admin", password: "secret"

  # Verify the user is signed in
  assert_equal "admin", session[:username]
end

...

def test_editing_document
  sign_in_user

  # Then, test something that required being signed in
  get "/changes.txt/edit"

  assert_equal 200, last_response.status
end
```

This is an improvement, but it still means going through the sign in process at the beginning of many tests. In the case of some applications, nearly all the functionality involves being within the context of a user, and that means most of the tests will have to create a signed in user. This makes the test suite slow to run.

Instead of walking through the sign-in process within each test, another option is to set the same values in the session ourselves that would be set by successfully submitting the sign in form. This way, we can skip the sign in process entirely and move right on to the purpose of each test. `Rack::Test` provides a way to set values into its internal `env` hash by passing them as the third argument to any of the request-making methods such as `get` and `post`. We can use this to provide a value for `rack.session,` which is what Rack uses internally to store the values in the session.

```ruby
def test_editing_document
  # By passing a value for the session, we can skip right to testing
  # functionality that requires being signed in. The second argument is
  # an empty hash because we aren't passing any params to the request.
  get "/changes.txt/edit", {}, { "rack.session" => { username: "admin" } }

  assert_equal 200, last_response.status
end
```

In order to make our tests a bit cleaner and avoid repeating the nested Hash structure over and over again, it can be moved to a method:

```ruby
def admin_session
  { "rack.session" => { username: "admin" } }
end

...

def test_editing_document
  get "/changes.txt/edit", {}, admin_session

  assert_equal 200, last_response.status
end
```

Keep in mind that a value that is set into the session using this technique will remain there until it is cleared by the application or a test. This means that if multiple requests are made within a test, only the first one needs to pass along the `admin_session`:

```ruby
def test_editing_document
  get "/changes.txt/edit", {}, admin_session

  assert_equal 200, last_response.status

  # Already signed in, so no need to pass values for rack.session
  get "/changes.txt/edit"

  assert_equal 200, last_response.status
end
```

**Requirements**

* When a signed-out user attempts to perform the following actions, they should be redirected back to the index and shown a message that says "You must be signed in to do that.":
  * Visit the edit page for a document
  * Submit changes to a document
  * Visit the new document page
  * Submit the new document form
  * Delete a document

**Implementation**

* In the specified privileged routes, check for a signed in user.
  * If not present, set the specified session message and redirect to index.
  * If present, continue with existing behavior already in the route.
* In the test file, define an `admin_session` method that returns a hash with a `'rack.session'` key with a value of `{ username: 'admin' }`.
* Implement tests for each of the specified privileged routes that test both cases (signed in user and no user).

---

### Storing User Accounts in an External File - 11/18/2018

**Requirements**

1. An administrator should be able to modify the list of users who may sign into the application by editing a configuration file using their text editor.

**Hint**

YAML is a good format to use to store this type of data because it can store data structures (as opposed to simple values such as Strings) and it can be easily read both by a Ruby program and a human.

The user credentials can be stored in a Hash, with usernames as keys and passwords as values:

```
{
  bill: billspassword,
  sonia: soniaspassword
}
```

**Implementation**

* Create `users.yml`, a YAML configuration file to contain a list of users and passwords.
* In the main app file, in a `before` block, read users and passwords from `users.yml` into instance variables.
* Refactor authentication from being hard coded to being a method that compares against the instance variables of users and passwords.

**Corrections based on provided Implementation/Solution**

* Adjust `config_path` method to use `/test/config/users.yml` during testing.
* Users only need to be read from file for the signing in route, not every route.

---

### Storing Hashed Passwords - 11/19/2018

So far we've been storing passwords as plain text, which is something that should **never** be done in a production application. User passwords should always be stored after being _hashed_, which is a one-way operation that makes the original content of the password practically impossible to recover. In order to compare a password provided by a user (say, in a `params` hash) with a hashed password, the raw password is hashed using the same algorithm. The resulting hashed value is then compared to the stored hashed value. If they match, then the original values of both hashes were the same.

The benefit here is that you don't have to store the raw password anywhere. So if someone were to gain access to the file or database where the passwords are stored, the passwords can't be used on other sites (it is extremely common for users to use the same passwords across different sites). Reducing this kind of liability is a good security practice.

> For some more background on user authentication and hashing passwords, read [this article](https://launchschool.com/blog/authentication-methods-in-rails) (it talks about authentication within Rails, but the information on password hashing is still relevant to our purposes.)

> For more information on **bcrypt**, the hashing technique we're using in this project, read [this article](http://dustwell.com/how-to-handle-passwords-bcrypt.html).

**Requirements**

1. User passwords must be hashed using bcrypt before being stored so that raw passwords are not being stored anywhere.

**Implementation**

* Update `Gemfile` to require `bcrypt` and `bundle install`.
* In the app file, `require bcrypt`.
* Edit `users.yml` to save a bcrypt hashed password instead of plaintext.
  * This app doesn't yet have the ability to create new users, so this can be done in IRB: `digest = BCrypt::Password.create(password)`
* Refactor app's authentication method:
  * Create a new BCrypt password with user's input: `BCrypt::Password.new(digest) == password`
  * Compare this new hashed password with the stored hashed password for authentication.

**Questions**

1. _True or false_: Running the same password through `bcrypt` multiple times will result in the same hashed value every time.
> False: running the same password through `bcrypt` multiple times will result in different hashed values because `bcrypt` uses a "per user" salt: the salt is randomized for each "new" password (each "run through").

---

### Next Steps - 11/19/2018

We encourage you to explore this project further or create another of your own to practice some of the techniques we've covered in this project and the course as a whole. Here are a few ideas:

---
#### 1. Validate that document names contain an extension that the application supports.

**Implementation**

* App already checks file extension to set `Content-Type` header; extend this behavior:
  * If there is no extension, raise an error, set a suitable session message, and redirect to index.
  * If there is an unsupported extension, app could either:
    * raise an error, set a suitable session message, and redirect to index, or...
    * ~~exert a "best effort" at displaying the file - probably either as html or plain text. Experiment.~~ Since files can't currently be uploaded, it doesn't make sense to "best effort" render unsupported extensions; when the best effort works, you get non txt extensions that are displayed as plain text, rendering the extension meaningless.

---

Add a "duplicate" button that creates a new document based on an old one.
Extend this project with a user signup form.
Add the ability to upload images to the CMS (which could be referenced within markdown files).
Modify the CMS so that each version of a document is preserved as changes are made to it.
