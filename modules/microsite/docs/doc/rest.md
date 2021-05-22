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

### Login with username/password

```
$ curl -d'{"account":"eike", "password":"test"}' http://localhost:9090/api/v2/open/auth/login
```

Output:
```
{"id":"6ExuF2eYpvd-hFPyEk4jAdy-aGiyyyDRk3q-nHkAE6kjViU","user":"eike","admin":false,"success":true,"message":"Login successful","token":"1577122333196-NkV4dUYyZVlwdmQtaEZQeUVrNGpBZHktYUdpeXl5RFJrM3EtbkhrQUU2a2pWaVUvZWlrZS9mYWxzZQ==-$2a$10$t5OpvGG8/t0.Dw2CO3RSN.-Lnow8nTb4t9nVMBkJEJbaRwABGY=","validMs":300000}
```

The `token` must be used with subsequent requests. It is valid for 5 minutes.

### Get a new token

```
$ curl -XPOST -H 'Sharry-Auth: 1577122333196-NkV4dUYyZVlwdmQtaEZQeUVrNGpBZHktYUdpeXl5RFJrM3EtbkhrQUU2a2pWaVUvZWlrZS9mYWxzZQ==-$2a$10$t5OpvGG8/t0.Dw2CO3RSN.-Lnow8nTb4t9nVMBkJEJbaRwABGY=' http://localhost:9090/api/v2/sec/auth/session
```

Output:
```
{"id":"6ExuF2eYpvd-hFPyEk4jAdy-aGiyyyDRk3q-nHkAE6kjViU","user":"eike","admin":false,"success":true,"message":"Login successful","token":"1577122497189-NkV4dUYyZVlwdmQtaEZQeUVrNGpBZHktYUdpeXl5RFJrM3EtbkhrQUU2a2pWaVUvZWlrZS9mYWxzZQ==-$2a$10$9/VNIq8e3YxHKTLyE0JwbO-bI0CpZnEsmfhDHxsjwhe7qzQaSY=","validMs":300000}
```

### Get your shares

```
$ curl -XGET -H 'Sharry-Auth: 1577122333196-NkV4dUYyZVlwdmQtaEZQeUVrNGpBZHktYUdpeXl5RFJrM3EtbkhrQUU2a2pWaVUvZWlrZS9mYWxzZQ==-$2a$10$t5OpvGG8/t0.Dw2CO3RSN.-Lnow8nTb4t9nVMBkJEJbaRwABGY=' http://localhost:9090/api/v2/sec/share/search
```

Output:
```
{"items":[{"id":"7wNPzKepw4g-gKgSfQ376tJ-HSifxLc33r5-xY8FigeF7wG","name":null,"aliasName":null,"validity":172800000,"maxViews":30,"password":false,"created":1577102005295,"files":
1,"size":199640,"published":null},{"id":"44EPQPe7Lo2-KnUCp3kiQNg-dJ4oxiAQ5Lh-etMiDwe5KD3","name":null,"aliasName":null,"validity":172800000,"maxViews":30,"password":false,"created
":1577101969643,"files":1,"size":192886,"published":null}]}
```

### Create an alias page

```
$ curl -XPOST -H 'Sharry-Auth: 1577122785983-NkV4dUYyZVlwdmQtaEZQeUVrNGpBZHktYUdpeXl5RFJrM3EtbkhrQUU2a2pWaVUvZWlrZS9mYWxzZQ==-$2a$10$kceo1M6cRNpMpptb0F67uO-sZurk/s03VHuzpxLGhT+AUF4TjU=' -d'{"name":"test alias","validity": 172800000, "enabled":true,"members":[]}' http://localhost:9090/api/v2/sec/alias
```

Output:
```
{"success":true,"message":"Alias successfully created.","id":"HfHViHEN5EM-E6jmgmw1W3H-KVUR2KanbEd-EGvDeZR2RPV"}
```

### Upload a file to the new alias page

Using the id, upload files via `multipart/form-data` requests. You can
upload multiple files at once.

```
$ curl -XPOST -F file=@P1020416.JPG -F file=@P1020422.JPG -H 'Sharry-Alias: HfHViHEN5EM-E6jmgmw1W3H-KVUR2KanbEd-EGvDeZR2RPV' http://localhost:9090/api/v2/alias/upload
```

Output:
```
{"success":true,"message":"Share created.","id":"8P7GzxmLGjF-F7K4kXAhe8j-6AhLrQuFJGb-i54TTRZ3xn8"}
```

### Get Details about the share

This requires authenticated users, of course. The `| jq` pipes the
one-line json output through a program that formats it.

```
$ curl -H'Sharry-Auth: 1577132299230-NkV4dUYyZVlwdmQtaEZQeUVrNGpBZHktYUdpeXl5RFJrM3EtbkhrQUU2a2pWaVUvZWlrZS9mYWxzZQ==-$2a$10$jFhOEGYktHb8yiLF5mhHjO-CvDL2MniUH+RQv8dTSWPwhSUeIw=' http://localhost:9090/api/v2/sec/share/8P7GzxmLGjF-F7K4kXAhe8j-6AhLrQuFJGb-i54TTRZ3xn8 | jq
```

Output:
```
{
  "id": "8P7GzxmLGjF-F7K4kXAhe8j-6AhLrQuFJGb-i54TTRZ3xn8",
  "name": null,
  "aliasId": "HfHViHEN5EM-E6jmgmw1W3H-KVUR2KanbEd-EGvDeZR2RPV",
  "aliasName": "test alias",
  "validity": 172800000,
  "maxViews": 30,
  "password": false,
  "descriptionRaw": null,
  "description": null,
  "created": 1577132473544,
  "publishInfo": null,
  "files": [
    {
      "id": "6QcXQ9qeSQb-VYF2p9M23XT-bMPRFkmtsPK-ejjJUns3Ymk",
      "filename": "P1020416.JPG",
      "size": 2829079,
      "mimetype": "image/jpeg",
      "checksum": "8ffe8da9d49b7e6590b78362ed0acd4156f4bccaa724c710560a57bd3c54d74d",
      "storedSize": 2829079
    },
    {
      "id": "Eur8FJj4uxL-q9NYVBqYi1L-jnsEFKPwCYQ-6Z81iazysjD",
      "filename": "P1020422.JPG",
      "size": 3692609,
      "mimetype": "image/jpeg",
      "checksum": "424bcfa141f61a73269466102ee1a826f1fae31a847a5861500fc4cbdfb1732f",
      "storedSize": 3692609
    }
  ]
}
```

The output contains the two files that have been uploaded. Also
interesting is the `storedSize` property. This indicates how many
bytes really reached the server. The `size` property uses the value as
advertised by the uploader. If `storedSize` does not equal `size` then
the file is not fully uploaded.
