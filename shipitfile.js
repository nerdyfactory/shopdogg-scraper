var path = require('path');

module.exports = function (shipit) {
  require('shipit-deploy')(shipit);

  shipit.initConfig({
    default: {
      workspace: '/tmp/shopdogg',
      deployTo: '/var/www/shopdogg',
      repositoryUrl: 'https://bitbucket.org/shopdogg/shopdogg-scraper.git',
      ignores: ['.git'],
      keepReleases: 2,
      deleteOnRollback: false,
      //key: '/path/to/key',
      shallowClone: false
    },
    production: {
      servers: 'shopdogg@188.166.229.186'
    }
  });

  shipit.currentPath = path.join(shipit.config.deployTo, 'current');

  shipit.on('published', function () {
    // npm install modules
    shipit.remote('cd '+shipit.currentPath+' && npm install')
    .then(function () {
      shipit.log("Install finished");
      shipit.emit('installed');
    });
  });

  shipit.on('installed', function () {
    // compile
    shipit.remote('cd '+shipit.currentPath+' && grunt')
    .then(function () {
      shipit.log("Compile finished");
      shipit.log("Done");
    });
  });
};
