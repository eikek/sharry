---
layout: docs
title: Reverse Proxy
permalink: doc/reverseproxy
---

# {{ page.title }}

This contains examples for how to use sharry behind a reverse proxy.

For the examples below, assume the following:

- Sharry app is available at `192.168.1.11:9090`.
- The external domain/hostname is `sharry.example.com`

## Configuring Sharry

These settings require a complement config part in the sharry
configuration file:

- First, if Sharry REST server is on a different machine, you need to
  change the `bind.address` setting to be either `0.0.0.0` or the ip
  address of the network interface that the reverse proxy server
  connects to.

  ```
  sharry.restserver {
    # Where the server binds to.
    bind {
      address = "192.168.1.11"
      port = 9090
    }
  }
  ```

  Note that a value of `0.0.0.0` instead of `192.168.1.11` will bind
  the server to every network interface. If it is running on the same
  machine as the reverse proxy server, you can set `localhost`
  instead.
- Sharry needs to know the external url. The `base-url` setting must
  point to the external address. Using above values, it must be set to
  `https://sharry.example.com`.

  ```
  sharry.restserver {

    # This is the base URL this application is deployed to. This is used
    # to create absolute URLs and to configure the cookie.
    #
    # Note: Currently deploying behind a path is not supported. The URL
    # should not end in a slash.
    base-url = "https://sharry.example.com"
    ...
  }
  ```
- The maximum request size should probably be increased at the reverse
  proxy. This depends on your machine, of course. The sharry related
  setting is `sharry.restserver.webapp.chunk-size`. This defines the
  size that is used for uploading chunks of data in one request.

  ```
  sharry.restserver {
    webapp {
      # Chunk size used for one request. The server will re-chunk the
      # stream into smaller chunks. But the client can transfer more in
      # one requests, resulting in faster uploads.
      #
      # You might need to adjust this value depending on your setup. A
      # higher value usually means faster uploads.
      chunk-size = "100M"
  }
  ```

  Here a chunk-size of 100M is used and the reverse proxy must be set
  to at least this value. Below it is set to 105M, just to be sure.


If you have examples for more servers, please let me know or add it to
this site.

## Nginx

This defines two servers: one listens for http traffic and redirects
to the https variant. Additionally it defines the let's encrypt
`.well-known` folder name.

The https server endpoint is configured with the let's encrypt
certificates and acts as a proxy for the application at
`192.168.1.11:9090`.

The setting `client_max_body_size` is relevant, too. This is the
maximum size of a single requests. This must be greater than sharry's
`webapp.chunk-size` setting.

The setting `proxy_buffering off;` disables buffering responses from
the application coming to nginx. Buffering may introduce backpressure
problems if the client is not reading fast enough. The response coming
from the application may quickly be too large to fit in memory and
nginx then writes a temporary file (which is limited to 1G by
default). If this limit is reached, nginx waits until the client has
received all disk buffered data which in turn can result in send
timeouts.


```
http {
    map $http_upgrade $connection_upgrade {
        default upgrade;
        '' close;
    }

    server {
        listen 0.0.0.0:80 ;
        listen [::]:80 ;
        server_name subdomain.otherdomain.tld ;
        location /.well-known/acme-challenge {
            root /var/data/nginx/ACME-PUBLIC;
            auth_basic off;
        }
        location / {
            return 301 https://$host$request_uri;
        }
    }
    server {
        listen 0.0.0.0:443 ssl http2 ;
        listen [::]:443 ssl http2 ;
        server_name sharry.example.com ;
        location /.well-known/acme-challenge {
            root /var/data/nginx/ACME-PUBLIC;
            auth_basic off;
        }
        ssl_certificate /var/lib/acme/sharry.example.com/fullchain.pem;
        ssl_certificate_key /var/lib/acme/sharry.example.com/key.pem;
        ssl_trusted_certificate /var/lib/acme/sharry.example.com/full.pem;
        location / {
            proxy_pass http://192.168.1.11:9090;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;

            proxy_set_header    Host                $host;
            proxy_set_header    X-Real-IP           $remote_addr;
            proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
            proxy_set_header    X-Forwarded-Proto   $scheme;

            proxy_buffering off;
            client_max_body_size 105M;
            proxy_send_timeout   300s;
            proxy_read_timeout   300s;
            send_timeout         300s;
        }
    }
}
```
