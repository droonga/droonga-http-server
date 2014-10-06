var options = require('commander');

var version = require('../package.json').version;
var defaultConfigs = require('./default-configs');

options.port             = defaultConfigs.port;
options.accessLogFile    = defaultConfigs.access_log_file;
options.systemLogFile    = defaultConfigs.system_log_file;
options.systemLogLevel   = defaultConfigs.system_log_level;
options.daemon           = defaultConfigs.daemon;
options.pidFile          = defaultConfigs.pid_file
options.cacheSize        = defaultConfigs.cache_size;
options.enableTrustProxy = defaultConfigs.enable_trust_proxy;
options.plugins          = defaultConfigs.plugins;
options.environment      = defaultConfigs.environment;

options.droongaEngineHostName = defaultConfigs.engine.host;
options.droongaEnginePort     = defaultConfigs.engine.port;
options.tag                   = defaultConfigs.engine.tag;
options.defaultDataset        = defaultConfigs.engine.default_dataset;
options.receiveHostName       = defaultConfigs.engine.receive_host;

function intOption(newValue, oldValue) {
  return parseInt(newValue);
}

function pluginsOption(newValue, oldValue) {
  return newValue.split(/\s*,\s*/).map(function (plugin) {
    return require(plugin);
  });
}

function generateOptionHandler(onHandle, converter) {
  return function(newValue, oldValue) {
    onHandle(newValue);
    if (converter)
      return converter(newValue);
    else
      return newValue;
  };
}


options = options
  .version(version);

function add() {
  options = options.option.apply(options, arguments);
  return exports;
}
exports.add = add;

function define() {
  add('--port <port>',
      'Port number (' + options.port + ')',
      generateOptionHandler(function() {
        options.portGiven = true;
      }, intOption));
  add('--receive-host-name <name>',
      'Host name of the protocol adapter. ' +
        'It must be resolvable by Droonga engine. ' +
        '(' + options.receiveHostName + ')',
      generateOptionHandler(function() {
        options.receiveHostNameGiven = true;
      }));
  add('--droonga-engine-host-name <name>',
      'Host name of Droonga engine (' + options.droongaEngineHostName + ')',
      generateOptionHandler(function() {
        options.droongaEngineHostNameGiven = true;
      }));
  add('--droonga-engine-port <port>',
      'Port number of Droonga engine (' + options.droongaEnginePort + ')',
      generateOptionHandler(function() {
        options.droongaEnginePortGiven = true;
      }, intOption));
  add('--default-dataset <dataset>',
      'The default dataset (' + options.defaultDataset + ')',
      generateOptionHandler(function() {
        options.defaultDatasetGiven = true;
      }));
  add('--tag <tag>',
      'The tag (' + options.tag + ')',
      generateOptionHandler(function() {
        options.tagGiven = true;
      }));
  add('--access-log-file <file>',
      'Output access logs to <file>. ' +
        'You can use "-" as <file> to output to the standard output. ' +
        '(' + options.accessLogFile + ')',
      generateOptionHandler(function() {
        options.accessLogFileGiven = true;
      }));
  add('--system-log-file <file>',
      'Output system logs to <file>. ' +
        'You can use "-" as <file> to output to the standard output. ' +
        '(' + options.systemLogFile + ')',
      generateOptionHandler(function() {
        options.systemLogFileGiven = true;
      }));
  add('--system-log-level <level>',
      'Log level for the system log. ' +
        '(' + options.systemLogLevel + ')',
      generateOptionHandler(function() {
        options.systemLogLevelGiven = true;
      }));
  add('--cache-size <size>',
      'The max number of cached requests ' +
        '(' + options.cacheSize + ')',
      generateOptionHandler(function() {
        options.cacheSizeGiven = true;
      }, intOption));
  add('--enable-trust-proxy',
      'Enable "trust proxy" configuration. It is required when you run droonga-http-server behind a reverse proxy. ' +
        '(' + options.enableTrustProxy + ')',
      generateOptionHandler(function() {
        options.enableTrustProxyGiven = true;
      }));
  add('--plugins <plugin1,plugin2,...>',
      'Use specified plugins. ' +
        '(' + options.plugins.join(',') + ')',
      generateOptionHandler(function() {
        options.pluginsGiven = true;
      }, pluginsOption));
  add('--daemon',
      'Run as a daemon. (' + options.daemon + ')',
      generateOptionHandler(function() {
        options.daemonGiven = true;
      }));
  add('--pid-file <pid-file>',
      'Output PID to <pid-file>.',
      generateOptionHandler(function() {
        options.pidFileGiven = true;
      }));
  add('--environment <environment>',
      'Use specified environment. (' + options.environment + ')',
      generateOptionHandler(function() {
        options.environmentGiven = true;
      }));
  return exports;
}
exports.define = define;

function parse(argv) {
  return options.parse(argv);
}
exports.parse = parse;
