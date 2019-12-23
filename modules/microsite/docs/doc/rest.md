---
layout: docs
title: Rest Api
permalink: doc/rest
---

# REST Api

Sharry is provided as a REST server and a web application client. The
REST Api is specified using openapi 3.0 and it's static documentation
can be seen [here](../openapi/sharry-openapi.html).

The "raw" `openapi.yml` specification file can be found
[here](../openapi/sharry-openapi.yml).

The calls are divided into 4 categories:

- `/open/*`: no authentication is required to access
- `/sec/*`: an authenticated user is required
- `/alias/*`: these routes are allowed with a valid *alias id* given
  as header `Sharry-Alias`
- `/admin/*`: an authenticated user that is admin is required

Authentication works by logging in with username/password (or an
oauth2 flow) that generates a token that has to be sent with every
request to a secured and admin route. It is possible to sent it via a
`Cookie` header or the special `Sharry-Auth` header.

Files can be uploaded using different methods. There is an endpoint
that can take all files and meta data from one single request. For
more reliable uploads, the server implements the [tus
protocol](https://tus.io/protocols/resumable-upload.html) that allows
to resume failed or paused uploads.

## Authentication

The unprotected route `/open/auth/login` can be used to login with
account name and password. The response contains a token that can be
used for accessing protected routes. The token is only valid for a
restricted time which can be configured (default is 5 minutes).

New tokens can be generated using an existing valid token and the
protected route `/sec/auth/session`. This will return the same
response as above, giving a new token.

This token can be added to requests in two ways: as a cookie header or
a "normal" http header. If a cookie header is used, the cookie name
must be `sharry_auth` and a custom header must be named
`Sharry-Auth`.

## Live Api

Besides the statically generated documentation at this site, the rest
server provides a openapi generated documenation, that allows playing
around with the api. It requires a running sharry rest server. If it
is deployed at `http://localhost:9090`, then check this url:

```
http://localhost:909/api/doc
```

## Examples

TODO
