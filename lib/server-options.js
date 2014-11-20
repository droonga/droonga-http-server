var options = require('commander');

var version = require('../package.json').version;
var defaultConfigs = require('./default-configs'),
    optionUtils    = require('./option-utils');

options.host             = defaultConfigs.host;
options.port             = defaultConfigs.port;
options.accessLogFile    = defaultConfigs.access_log_file;
options.systemLogFile    = defaultConfigs.system_log_file;
options.systemLogLevel   = defaultConfigs.system_log_level;
options.daemon           = defaultConfigs.daemon;
options.pidFile          = defaultConfigs.pid_file
options.cacheSize        = defaultConfigs.cache_size;
options.cacheTtlInSeconds = defaultConfigs.cache_ttl_in_seconds;
options.enableTrustProxy = defaultConfigs.enable_trust_proxy;
options.documentRoot     = defaultConfigs.document_root;
options.plugins          = defaultConfigs.plugins;
options.environment      = defaultConfigs.environment;

options.droongaEngineHostNames = defaultConfigs.engine.hosts;
options.droongaEnginePort      = defaultConfigs.engine.port;
options.tag                    = defaultConfigs.engine.tag;
options.defaultDataset         = defaultConfigs.engine.default_dataset;
options.receiveHostName        = defaultConfigs.engine.receive_host;

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
  add('--host <host>',
      'Host to listen (' + options.host + ')');
  add('--port <port>',
      'Port number (' + options.port + ')',
      optionUtils.intOption);
  add('--receive-host-name <name>',
      'Host name of the protocol adapter. ' +
        'It must be resolvable by Droonga engine. ' +
        '(' + options.receiveHostName + ')');
  add('--droonga-engine-host-names <name1,name2,...>',
      'List of Droonga engine nodes\' host name (' + options.droongaEngineHostNames.join(',') + ')',
      optionUtils.stringsOption);
  add('--droonga-engine-host-name <name1,name2,...>',
      'Alias of --droonga-engine-host-names for backward compatibility.',
      optionUtils.stringsOption);
  add('--droonga-engine-port <port>',
      'Port number of Droonga engine (' + options.droongaEnginePort + ')',
      optionUtils.intOption);
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
  add('--system-log-level <level>',
      'Log level for the system log. ' +
      '[silly,debug,verbose,info|warn,error]' +
        '(' + options.systemLogLevel + ')');
  add('--cache-size <size>',
      'The maximum number of cached responses ' +
        '(' + options.cacheSize + ')',
      optionUtils.intOption);
  add('--cache-ttl-in-seconds <seconds>',
      'The time to live of cached responses, in seconds ' +
        '(' + options.cacheTtlInSeconds + ')',
      optionUtils.intOption);
  add('--enable-trust-proxy',
      'Enable "trust proxy" configuration. It is required when you run droonga-http-server behind a reverse proxy. ' +
        '(' + options.enableTrustProxy + ')');
  add('--disable-trust-proxy',
      'Inverted option of --enable-trust-proxy.');
  add('--document-root <path>',
      'Path to the document root. ' +
        '(' + options.documentRoot + ')');
  add('--plugins <plugin1,plugin2,...>',
      'Use specified plugins. ' +
        '(' + options.plugins.join(',') + ')',
      optionUtils.pluginsOption);
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
  var parsedOptions = options.parse(argv);

  if (parsedOptions.disableTrustProxy)
    parsedOptions.enableTrustProxy = false;

  // for backward compatibility
  if (options.droongaEngineHostName &&
      options.droongaEngineHostName.length > 0 &&
      (!options.droongaEngineHostNames ||
       options.droongaEngineHostNames.length == 0))
    options.droongaEngineHostNames = options.droongaEngineHostName;

  return parsedOptions;
}
exports.parse = parse;
