# headrest

[![Build Status](https://travis-ci.org/natlownes/headrest.png?branch=master)](https://travis-ci.org/natlownes/headrest)

```npm install headrest```

Provides a RESTful,
[CORS](http://en.wikipedia.org/wiki/Cross-origin_resource_sharing) enabled
webserver intended for use when developing rest-backed Javascript apps for the
browser.  If you want to click around in your app, create/read/update/delete
objects, but not fire up an entire backend, that is what this is for.

Assumes you init your JS app with or otherwise set an api root URL from which your
models build the correct URL for their resource.

You can set the apiRoot like:

```coffeescript
headrest = require('headrest')(apiRoot: '/apis/', dbPath: '/tmp/gruntest.json')
# headrest is an express app
```

#### Resources

It assumes your resources have paths like:

* for a list of resources (index), ```/api/rocks``` or nested as deep as you
  like -  ```/api/rocks/ffeedc/sedimentaries``` and so on.
* for a single resource, ```/api/rocks/ffeedc```, also nested as far as you
  want.

#### Sessions

Implements sessions at ```/api/session```.

* POST whatever you want to ```/api/session```, you'll get a Cookie.

* GET ```/api/session``` - HTTP 200 means you're logged in, 404 if not.

* DELETE ```/api/session``` - removes your session record and sets your cookie
  to expire.

### Example Gruntfile.coffee

```coffeescript

headrest = require('headrest')(apiRoot: '/apis/', dbPath: '/tmp/gruntest.json')


module.exports = (grunt) ->
  grunt.loadNpmTasks('grunt-contrib-connect')

  grunt.registerTask('headrest',
    [
      'connect'
    ]
  )

  grunt.initConfig
    connect:
      headrest:
        options:
          port: 5001
          hostname: "0.0.0.0"
          keepalive: true
          middleware: (connect, options) ->
            [headrest]


```

```bash
grunt headrest
```

This will start the server on ```http://0.0.0.0:5001/```.  From a browser, you
can create an object with:

```javascript

var request = $.ajax({
  url: "http://localhost:5001/apis/rocks",
  dataType: "json",
  crossDomain: true,
  type: 'POST',
  data: {name: "sedimentary"}
})

request.done(function(d) {
  var rock = JSON.parse(d)
  console.log( rock.id )
})

// console output:
// > 7cf28fd544be1b7f55296c45d40538f

var request = $.ajax({
  url: "http://localhost:5001/apis/rocks/7cf28fd544be1b7f55296c45d40538f",
  dataType: "json",
  crossDomain: true,
  type: 'PUT',
  data: {name: "Igneous"}
})

request.done(function(d) {
  console.log('updated')
})

var request = $.ajax({
  url: "http://localhost:5001/apis/rocks/7cf28fd544be1b7f55296c45d40538f",
  dataType: "json",
  crossDomain: true,
  type: 'DELETE'
})

request.done(function(d) {
  console.log('removed')
})

```

### TODO:

* allow setting of session path.
* keep each record in separate file (next major ver)
* de-coffeeify?

### Contributing

Fork and

```npm install```

```npm test```

or

```cake test:watch```

Or if any of this code is wack and you think there's a better way to do it, I
definitely want to hear about it, no joke.

### That's it!

I yanked this idea from my homie Mark's footrest.py

