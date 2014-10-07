# News

## 1.0.8: 2014-10-07

 * Works correctly as a service even if you restarted the computer itself.
 * Log level of the system log is now customizable.
   You just have to put a line like `system_log_level: debug` into the `droonga-http-server.yaml`.
   And, `droonga-http-server-configure` also asks the log level.

## 1.0.7: 2014-09-29

 * The installation script is now available.
   It automatically installs required softwares and configure the `droonga-http-server` as a system service.
   Currently it works only for Debian, Ubuntu, and CentOS 7.
 * The service works as a process belonging to a user `droonga-http-server` who is specific for the service.
   The configuration directory for the service is placed under the home directory of the user.
 * A static configuration file to define default parameters (`port` and so on) is now available.
   It must be placed into the configuration directory specified by the environment variable `DROONGA_BASE_DIR`.
   You don't have to run `droonga-http-server` command with many options, anymore.
 * A new command line utility `droonga-http-server-configure` is available.
   It generates the static configuration file for the service.
 * Cached responses are now returned correctly.

## 1.0.6: 2014-07-29

 * Provides Groonga's administration page as the document root (`/`) experimentally.
 * Supports a new `--environment` option to override the `NODE_ENV` environment variable.

## 1.0.5: 2014-05-29

 * Use `Default` as the name of the default dataset.
   It is same to Droonga Engine's one.
 * Use `10041` as the default port number.
   It is same to Groonga HTTP server's one.

## 1.0.4: 2014-04-29

 * Works with the [Express 4.0](http://expressjs.com/).
 * Supports a new `--enable-trust-proxy` option to run the server behind a reverse proxy.
 * Supports a new `--plugins` option to choose plugins to be activated.
 * Supports new `--daemon` and `--pid-file` options for the daemon mode.

## 1.0.3: 2014-03-29

 * Fix broken dependencies.

## 1.0.2: 2014-03-29

 * Register bin/droonga-http-server command correctly.

## 1.0.1: 2014-03-29

The first release!
