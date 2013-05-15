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
