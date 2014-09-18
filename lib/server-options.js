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

options
  .version(version)
  .option('--port <port>',
          'Port number (' + options.port + ')',
          intOption)
  .option('--receive-host-name <name>',
          'Host name of the protocol adapter. ' +
            'It must be resolvable by Droonga engine. ' +
            '(' + options.receiverHostName + ')')
  .option('--droonga-engine-host-name <name>',
          'Host name of Droonga engine (' + options.droongaEngineHostName + ')')
  .option('--droonga-engine-port <port>',
          'Port number of Droonga engine (' + options.droongaEnginePort + ')',
          intOption)
  .option('--default-dataset <dataset>',
          'The default dataset (' + options.defaultDataset + ')')
  .option('--tag <tag>',
          'The tag (' + options.tag + ')')
  .option('--access-log-file <file>',
          'Output access logs to <file>. ' +
            'You can use "-" as <file> to output to the standard output. ' +
            '(' + options.accessLogFile + ')')
  .option('--system-log-file <file>',
          'Output system logs to <file>. ' +
            'You can use "-" as <file> to output to the standard output. ' +
            '(' + options.systemLogFile + ')')
  .option('--cache-size <size>',
          'The max number of cached requests ' +
            '(' + options.cacheSize + ')',
          intOption)
  .option('--enable-trust-proxy',
          'Enable "trust proxy" configuration. It is required when you run droonga-http-server behind a reverse proxy. ' +
            '(' + options.enableTrustProxy + ')')
  .option('--plugins <plugin1,plugin2,...>',
          'Use specified plugins. ' +
            '(' + options.plugins.join(',') + ')',
          pluginsOption)
  .option('--daemon',
          'Run as a daemon. (' + options.daemon + ')')
  .option('--pid-file <pid-file>',
          'Output PID to <pid-file>.')
  .option('--environment <environment>',
          'Use specified environment. (' + options.environment + ')')
  .parse(process.argv);

module.exports = options;
