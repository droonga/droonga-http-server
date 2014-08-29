# News

## 1.0.7: 2014-08-29 (planned)

 * A static configuration file to define default parameters (`port` and so on) is now available.
   It must be placed into the configuration directory specified by the environment variable `DROONGA_BASE_DIR`
   (same to the directory `catalog.json` exists, if `droonga-engine` also works on the computer.)
   You don't have to run "droonga-http-server" command with many options, anymore.
 * `droonga-http-server-stop`, a new command line utility to stop the service is available.
   You don't need to send `SIGTERM` manually anymore.

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
