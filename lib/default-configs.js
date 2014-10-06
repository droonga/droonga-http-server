var droonga = require('express-droonga'),
    fs      = require('fs'),
    yaml    = require('js-yaml'),
    path    = require('path');

var baseDir = path.resolve(process.env.DROONGA_BASE_DIR || '.');

var engineConfigs = {};
var engineServiceUserName = 'droonga-engine';
var engineServiceBaseDir  = '/home/' + engineServiceUserName + '/droonga';

function setBaseDir(baseDir) {
  var configs = {};

  var configFile = path.resolve(baseDir, 'droonga-http-server.yaml');
  if (fs.existsSync(configFile)) {
    configs = yaml.safeLoad(fs.readFileSync(configFile, 'utf8'));
    if (!('daemon' in configs))
      configs.daemon = true;
  }

  var engineServiceConfigFile = path.resolve(engineServiceBaseDir, 'droonga-engine.yaml');
  if (fs.existsSync(engineServiceConfigFile)) {
    engineConfigs = yaml.safeLoad(fs.readFileSync(engineServiceConfigFile, 'utf8'));
  }
  else {
    var engineConfigFile = path.resolve(baseDir, 'droonga-engine.yaml');
    if (fs.existsSync(engineConfigFile)) {
      engineConfigs = yaml.safeLoad(fs.readFileSync(engineConfigFile, 'utf8'));
    }
  }

  configs.baseDir = baseDir;
  configs = defineDefaultConfigs(configs);
  configs.setBaseDir = setBaseDir;
  return configs;
}

function define(slot, path, value) {
  var keys = path.split('.');
  keys.some(function(key, index) {
    if (index == keys.length - 1) {
      if (!(key in slot))
        slot[key] = value;
    } else {
      if (!(key in slot))
        slot[key] = {};
      slot = slot[key];
    }
  });
}

function defineDefaultConfigs(configs) {
define(engineConfigs, 'host', '127.0.0.1');
define(engineConfigs, 'port', 10031);
define(engineConfigs, 'tag',  'droonga');

define(configs, 'port',               10041);
define(configs, 'cache_size',         100);
define(configs, 'enable_trust_proxy', false);
define(configs, 'plugins', [
  droonga.API_REST,
  droonga.API_GROONGA,
  droonga.API_DROONGA
]);
define(configs, 'environment', process.env.NODE_ENV || 'development');

if (configs.daemon) {
  define(configs, 'pid_file',        'droonga-http-server.pid');
  define(configs, 'access_log_file', 'droonga-http-server.access.log');
  define(configs, 'system_log_file', 'droonga-http-server.system.log');
} else {
  define(configs, 'daemon',          false);
  define(configs, 'access_log_file', '-');
  define(configs, 'system_log_file', '-');
}
define(configs, 'system_log_level', 'warn');

define(configs, 'engine.host',            engineConfigs.host);
define(configs, 'engine.port',            engineConfigs.port);
define(configs, 'engine.tag',             engineConfigs.tag);
define(configs, 'engine.default_dataset', 'Default');
// We can use the host name of the droonga-engine as the receive host
// of the http server, because this computer works as a droonga-engine
// node and it is guaranteed that this computer can be accessed with
// the host name.
define(configs, 'engine.receive_host',    engineConfigs.host);

return configs;
}

module.exports = setBaseDir(baseDir);
