var options = require('commander');

var version = require('../package.json').version;
var defaultConfigs = require('./default-configs');

options.port             = defaultConfigs.port;
options.accessLogFile    = defaultConfigs.access_log_file;
options.systemLogFile    = defaultConfigs.system_log_file;
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
options.receiverHostName      = defaultConfigs.engine.receiver_host;

intOption = function(newValue, oldValue) {
  return parseInt(newValue);
}

pluginsOption = function(newValue, oldValue) {
  return newValue.split(/\s*,\s*/).map(function (plugin) {
    return require(plugin);
  });
}

options = options
  .version(version);

function add() {
  options = options.apply(options, arguments);
  return exports;
}
exports.add = add;

function define() {
  add('--port <port>',
          'Port number (' + options.port + ')',
          intOption);
  add('--receive-host-name <name>',
          'Host name of the protocol adapter. ' +
            'It must be resolvable by Droonga engine. ' +
            '(' + options.receiverHostName + ')');
  add('--droonga-engine-host-name <name>',
          'Host name of Droonga engine (' + options.droongaEngineHostName + ')');
  add('--droonga-engine-port <port>',
          'Port number of Droonga engine (' + options.droongaEnginePort + ')',
          intOption);
  add('--default-dataset <dataset>',
          'The default dataset (' + options.defaultDataset + ')');
  add('--tag <tag>',
          'The tag (' + options.tag + ')');
  add('--access-log-file <file>',
          'Output access logs to <file>. ' +
            'You can use "-" as <file> to output to the standard output. ' +
            '(' + options.accessLogFile + ')');
  add('--system-log-file <file>',
          'Output system logs to <file>. ' +
            'You can use "-" as <file> to output to the standard output. ' +
            '(' + options.systemLogFile + ')');
  add('--cache-size <size>',
          'The max number of cached requests ' +
            '(' + options.cacheSize + ')',
          intOption);
  add('--enable-trust-proxy',
          'Enable "trust proxy" configuration. It is required when you run droonga-http-server behind a reverse proxy. ' +
            '(' + options.enableTrustProxy + ')');
  add('--plugins <plugin1,plugin2,...>',
          'Use specified plugins. ' +
            '(' + options.plugins.join(',') + ')',
          pluginsOption);
  add('--daemon',
          'Run as a daemon. (' + options.daemon + ')');
  add('--pid-file <pid-file>',
          'Output PID to <pid-file>.');
  add('--environment <environment>',
          'Use specified environment. (' + options.environment + ')');
  return exports;
}
exports.define = define;

function parse(argv) {
  return options.parse(argv);
}
exports.parse = parse;
