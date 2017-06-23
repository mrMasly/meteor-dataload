Package.describe({
  name: 'mrmasly:dataload',
  version: '0.0.2',
  summary: 'meteor dataload',
  git: 'https://github.com/mrMasly/meteor-dataload',
  documentation: 'README.md'
});

Npm.depends({
  'lodash': '4.17.4',
  'fs-extra': '3.0.1',
  'yandex-disk': '0.0.8',
  'md5': '2.2.1',
  'googleapis': '19.0.0',
  'readline': '1.3.0',
  'google-auth-library': '0.10.0'
});


Package.onUse(function(api) {
  api.versionsFrom('1.5');
  
  api.use('ecmascript@0.8.1');
  api.use('coffeescript@1.12.6_1');
  api.use('mrmasly:meteor-root@0.0.1');
  api.use('mongo@1.1.18');

  api.mainModule('src/index.coffee', 'server');
  api.export('Dataload', 'server');

});
