var droonga = require('express-droonga'),
    fs      = require('fs'),
    yaml    = require('js-yaml'),
    path    = require('path');

var configs = {};

var baseDir = path.resolve(process.env.DROONGA_BASE_DIR || ".");

var configFile = path.resolve(baseDir, "droonga-http-server.yaml");
if (fs.existsSync(configFile)) {
  configs = yaml.safeLoad(fs.readFileSync(configFile, 'utf8'));
  if (!('daemon' in configs)) {
    configs.daemon   = true;
    configs.pid_file = 'droonga-http-server.pid';
  }
}

function define(path, value) {
  var slot = configs;
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

define('port',               10041);
define('access_log_file',    '-');
define('system_log_file',    '-');
define('cache_size',         100);
define('enable_trust_proxy', false);
define('plugins', [
  droonga.API_REST,
  droonga.API_GROONGA,
  droonga.API_DROONGA
]);
define('environment', process.env.NODE_ENV || 'development');

define('engine.host',            '127.0.0.1');
define('engine.port',            10031);
define('engine.tag',             'droonga');
define('engine.default_dataset', 'Default');
define('engine.receiver_host',   '127.0.0.1');

configs.baseDir = baseDir;

module.exports = configs;
