# README

This is an HTTP Protocol Adapter for the Droonga Engine.

## Usage

### Server

If both this and fluentd are running on the same machine,
you can run this easily.

    $ npm install -g droonga-http-server
    $ droonga-http-server

Otherwise, you have to specify pairs of host and port to send messages
to the fluentd and to receive messages from the fluentd.

    $ droonga-http-server \
        --droonga-engine-host-name "backend.droonga.example.org" \
        --droonga-engine-port 24224 \
        --receive-host-name "frontend.droonga.example.org"

### Client

Frontend applications can call HTTP APIs to access resources stored in
the droonga. For example:

    GET /droonga/tables/entries?query=foobar HTTP/1.1

It works as a search request, and a JSON string will be returned as the result.

## License

The MIT License. See LICENSE for details.

Copyright (c) 2014 Droonga project
