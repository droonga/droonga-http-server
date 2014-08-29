var droonga = require('express-droonga'),
    fs      = require('fs'),
    yaml    = require('js-yaml'),
    path    = require('path');

var baseDir = path.resolve(process.env.DROONGA_BASE_DIR || ".");

var configs = {};
var engineConfigs = {};

var configFile = path.resolve(baseDir, "droonga-http-server.yaml");
if (fs.existsSync(configFile)) {
  configs = yaml.safeLoad(fs.readFileSync(configFile, 'utf8'));
  if (!('daemon' in configs))
    configs.daemon = true;
}

var engineConfigFile = path.resolve(baseDir, "droonga-engine.yaml");
if (fs.existsSync(engineConfigFile)) {
  engineConfigs = yaml.safeLoad(fs.readFileSync(engineConfigFile, 'utf8'));
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
  define(configs, 'access_log_file',    '-');
  define(configs, 'system_log_file',    '-');
}

define(configs, 'engine.host',            engineConfigs.host);
define(configs, 'engine.port',            engineConfigs.port);
define(configs, 'engine.tag',             engineConfigs.tag);
define(configs, 'engine.default_dataset', 'Default');
define(configs, 'engine.receiver_host',   '127.0.0.1');

configs.baseDir = baseDir;

module.exports = configs;
