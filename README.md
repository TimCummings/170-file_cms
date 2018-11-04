
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
