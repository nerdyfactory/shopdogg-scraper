module.exports = (grunt) ->
  grunt.initConfig
    coffee:
      glob_to_multiple:
        expand: true
        options:
          bare: true
        src: [
          './*.coffee',
          'src/**/*.coffee'
        ]
        ext: '.js'
    watch:
      files: [
          './*.coffee',
        'src/**/*.coffee'
      ]
      tasks: ['coffee']
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.registerTask 'default', ['coffee']
