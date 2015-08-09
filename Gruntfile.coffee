module.exports = (grunt) ->
  grunt.initConfig
    coffee:
      glob_to_multiple:
        expand: true
        options:
          bare: true
        src: [
          'main.coffee',
          '*/**/*.coffee'
        ]
        ext: '.js'
    watch:
      files: [
        '*/**/*.coffee'
      ]
      tasks: ['coffee']
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.registerTask 'default', ['coffee']
