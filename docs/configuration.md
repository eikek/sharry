[Contents](index.md)

# Configuration

Once you downloaded or build sharry, you can run the sharry server by
executing the `jar.sh` file. This file has one main argument: the
configuration file. Sharry doesn't look at any predefined directory
but expects the configuration to be passed.

You can quit the server by pressing `Ctrl-C`. Alternatively, use the
`--console` argument. This way you can quit the server by pressing
`Enter`, it will then shutdown gracefully.

## Format

The format is called [HOCON](https://github.com/typesafehub/config#using-hocon-the-json-superset) which is a superset of [JSON](http://json.org/). For
the details, see [its specification](https://github.com/typesafehub/config/blob/master/HOCON.md).

The HOCON format allows to create a hierarchical layout, where a key
is a path. Path elements are separated by a dot `.`. So writing

```
sharry {
   authc {
     extern {
       admin = true
     }
   }
}
```

is the same as

```
sharry {
  authc {
    extern.admin = true
  }
}
```

or in one line:

```
sharry.authc.extern.admin = true
```

All config values related to Sharry are nested in a main `sharry`
namespace:

```
sharry {
  …
}
```

Every value in the custom config file will override the corresponding
one from the default config. So only what's different needs to be
specified.

Besides the configuration file, every option can be overridden by a
corresponding system property. They are passed to the java command:

```
SHARRY_JAVA_OPTS="-Dsome.property=value sharry-server-{{versionShort}}.jar.sh
```

For all possible options, please refer to the default configuration at
the bottom of the page.  It shows every setting with its default value
and a description. The following now explains some specific settings.

## Required settings

The most important settings you probably always want to change are:

```
sharry {
  web {
    # the host for binding the http server
    bind-host = "0.0.0.0"

    # the port for binding the http server
    bind-port = 9090

    # The base url to use when constructing urls.
    baseurl = "http://localhost:9090/"
  }
}
```

`bind-host` and `bind-port` specify the address to bind the http
server to. Then `baseurl` must be the url where sharry is
deployed. The default setting works if it is running and accessed
locally from `localhost:9090`.

The `baseurl` setting is important, because sharry resricts
the [http cookie](https://en.wikipedia.org/wiki/HTTP_cookie) used for auhtentication based on this value. The
cookie will only work for the domain in this url. Furthermore, all
absolute urls presented in the webapp are based on this value.


## Database

Sharry requires a sql database. Currently it works for [PostgreSQL](https://www.postgresql.org/)
and [H2](http://h2database.com/html/main.html). By default, sharry is configured to use a H2 database
which writes in a file in the current working directory.

Please open an [issue](https://github.com/eikek/sharry/issues) if you need support for other databases.

To change the db settings, specify a [JDBC](https://en.wikipedia.org/wiki/Java_Database_Connectivity) url, a driver class, a
username and a password:

```
sharry {
  db {
    driver = "org.h2.Driver"
    url = "jdbc:h2:./sharry-db.h2"
    user = "sa"
    password = ""
  }
}
```

The driver class is specific to each jdbc driver:

- H2: `org.h2.Driver`
- Postgres: `org.postgresql.Driver`

The jdbc url is also a little different for each database system:

- H2: `jdbc:h2:<relative-file-name>`
- Postgres: `jdbc:postgresql://<db-host>/<db-name>`

H2 needs a file which is created on first access. For postgres,
specify the full url to the database server.


## Authentication

Sharry manages accounts. Accounts only consists of a login and an
email. The email is optional and used to send notification emails.

Accounts can be authenticated via a password (internally) or via the
following:

- HTTP request
- System command
- a predefined admin account for getting started

These are configured in the `authc.extern.*` sections. If an account
doesn't exist, it is created on first login.

Only one of those methods should be configured. If multiple are
enabled, they are tried in _some_ order and the first that is
successful wins.

### Admin account

To get started, it is possible to setup an admin account via the
config file or system properties.

```
sharry.authc.extern.admin.enable = true
```

The account and password are both `admin` by default, but could be
changed by keys `login` and `password`.


### HTTP request

It is possible to authenticate a user by calling to another http
server. The response status code indicates about success and failure,
it must be `OK 200` for success. The relevant settings are self
describing:

```
sharry.authc.extern {
  # use a http request to do password verification. It only checks
  # the response status code for a 200.
  http {
    enable = false
    # the url to use, it may contain placeholders {login} and {password}
    url = "https://somehost/auth?login={login}&pass={password}"
    # the http method to use
    method = "POST"
    # the body of the request. it may be empty (for GET requests),
    # placeholders {login} and {password} can be used here
    body = """{ "login": "{login}", "pass": "{password}" }"""
    # if `body' is non-empty, use this contentType
    content-type = "application/json"
  }
}
```

The `url` is the url to use for the request. The placeholders
`{login}` and `{password}` are replaced by the values from the login
form. This applies to other values as well. The config format allows
to use tripple quotes that makes it more convenient to have single
quotes in the value. Otherwise you need to escape them with a
backslash.

### System command

Another way to authenticate a user is a system command. This is a last
resort and can be used to integrate other forms of authentication
(e.g. LDAP). You need to write a program or script that accepts
username and password and does the authentication. The return code
indicates about success or failure.

Here are the relevant settings:

```
sharry.authc.extern {
  # use a system command and pass the login and password via
  # placeholder {login} and {password}.
  command {
    enable = false
    program = [
      "/path/to/someprogram"
      "{login}"
      "{password}"
    ]
    # the return code to consider successful verification
    success = 0
  }
}
```

The `program` array contains the path to the program or script as
first element and all subsequent elements are arguments to the
program. Again, placholders `{login}` and `{password}` are replaced by
the corresponding user input.


## Email

Email can be used to be notified when someone has uploaded something
to an alias page or you can send the new download page directly from
within sharry.

This most often requires correct smtp settings. These are specified in
this section:

```
sharry {
  smtp {
    host = ""
    port = 0
    user = ""
    password = ""
    from = "noreply@localhost"
  }
}
```

If these settings are left default, sharry tries to send mail directly
to the mailserver of each email domain. This may or may not work,
usually depending on the policy of the receiving smtp server.

To enable or disable the mail forms in the webapplication, use this
setting:

```
sharry.web.mail.enable = true
```

Another value is this:

```
sharry.upload.enable-upload-notification = true
```

Which enables to send mails on finished uploads to an alias page.

## Reverse Proxy

When running behind a reverse proxy, it is importand to use HTTP
1.1. For example, a minimal nginx config would look like this:

```
server {
  listen 0.0.0.0:80;

  proxy_request_buffering off;
  proxy_buffering off;

  location / {
     proxy_pass http://127.0.0.1:9090;
     # this is important, because fs2-http can only do 1.1
     # and it effectively disables request_buffering
     proxy_http_version 1.1;
  }
}
```

## Default Configuration

The following is the default configuration as shipped with sharry for
reference.

```
{{& default-configuration}}
```
