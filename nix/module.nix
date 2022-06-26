{config, lib, pkgs, ...}:

with lib;
let
  cfg = config.services.sharry;
  user = if cfg.runAs == null then "sharry" else cfg.runAs;
  str = e: if (builtins.typeOf e) == "bool" then (if e then "true" else "false") else (builtins.toString e);
  sharryConf = pkgs.writeText "sharry.conf" ''
  {"sharry": { "restserver":
    ${builtins.toJSON cfg}
  }}
  '';
  defaults = {
    base-url = "http://localhost:9090";
    bind = {
      address = "localhost";
      port = 9090;
    };
    logging = {
      minimum-level = "Info";
      format = "Fancy";
      levels = {
        "sharry" = "Info";
        "org.flywaydb" = "Info";
        "binny" = "Info";
        "org.http4s" = "Info";
      };
    };
    response-timeout = "4 minutes";
    alias-member-enabled = true;
    webapp = {
      app-name = "Sharry";
      chunk-size = "100M";
      retry-delays = [0 3000 6000 12000 24000 48000];
      app-icon = "";
      app-icon-dark = "";
      app-logo = "";
      app-logo-dark = "";
      app-footer = "";
      app-footer-visible = true;
      welcome-message = "";
      auth-renewal = "4 minutes";
      default-language = "gb";
      initial-page = "home";
      default-validity = "7 days";
      initial-theme = "light";
      oauth-auto-redirect = true;
    };
    backend = {
      auth = {
        server-secret = "hex:caffee";
        session-valid = "8 minutes";
        fixed = {
          enabled = false;
          user = "admin";
          password = "admin";
          order = 10;
        };
        http = {
          enabled = false;
          url = "http://localhost:1234/auth?user={{user}}&password={{pass}}";
          method = "POST";
          body = "";
          content-type = "";
          order = 20;
        };
        http-basic = {
          enabled = false;
          url = "http://somehost:2345/path";
          method = "GET";
          order = 30;
        };
        command = {
          enabled = false;
          program = [
            "/path/to/someprogram"
            "{{user}}"
            "{{pass}}"
          ];
          success = 0;
          order = 40;
        };
        internal = {
          enabled = true;
          order = 50;
        };
        oauth = [
          {
            enabled = false;
            id = "github";
            name = "Github";
            icon = "fab fa-github";
            authorize-url = "https://github.com/login/oauth/authorize";
            token-url = "https://github.com/login/oauth/access_token";
            user-url = "https://api.github.com/user";
            user-id-key = "login";
            user-email-key = null;
            client-id = "<your client id>";
            client-secret = "<your client secret>";
          }
        ];
      };
      jdbc = {
        url = "jdbc:h2:///tmp/sharry-demo.db;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE";
        user = "sa";
        password = "";
      };
      signup = {
        mode = "open";
        invite-time = "14 days";
        invite-password = "generate-invite";
      };
      share = {
        chunk-size = "512K";
        max-size = "1.5G";
        max-validity = "365 days";
        database-domain-checks = [
          { enabled = false;
            native = "domain safe_bytea violates check constraint";
            message = "The uploaded file contains a virus!";
          }
        ];
      };
      cleanup = {
        enabled = true;
        interval = "14 days";
        invalid-age = "7 days";
      };
      mail = {
        enabled = false;
        smtp = {
          host = "localhost";
          port = 25;
          user = "";
          password = "";
          ssl-type = "starttls";
          check-certificates = true;
          timeout = "10 seconds";
          default-from = "";
          list-id = "Sharry";
        };
        templates = {
          download = {
            subject = "Download ready.";
            body = ''Hello,

there are some files for you to download. Visit this link:

{{{url}}}

{{#password}}
The required password will be sent by other means.
{{/password}}


Greetings,
{{user}} via Sharry
            '';
          };
          alias = {
            subject = "Link for Upload";
            body = ''Hello,

please use the following link to sent files to me:

{{{url}}}

Greetings,
{{user}} via Sharry
            '';
          };
          upload-notify = {
            subject = "[Sharry] Files arrived";
            body = ''Hello {{user}},

there have been files uploaded for you via the alias '{{aliasName}}'.
View it here:

{{{url}}}

Greetings,
Sharry
            '';
          };
        };
      };
    };
  };
in {

  ## interface
  options = {
    services.sharry = {
      enable = mkOption {
        default = false;
        description = "Whether to enable sharry.";
      };
      runAs = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Specify a user for running the application. If null, a new
          user is created.
        '';
      };


      base-url = mkOption {
        type = types.str;
        default = defaults.base-url;
        description = ''
          This is the base URL this application is deployed to. This is used
          to create absolute URLs and to configure the cookie.

          Note: Currently deploying behind a path is not supported. The URL
          should not end in a slash.
        '';
      };
      bind = mkOption {
        type = types.submodule({
          options = {
            address = mkOption {
              type = types.str;
              default = defaults.bind.address;
              description = "The address to bind the REST server to.";
            };
            port = mkOption {
              type = types.int;
              default = defaults.bind.port;
              description = "The port to bind the REST server";
            };
          };
        });
        default = defaults.bind;
        description = "Address and port bind the rest server.";
      };

      logging = mkOption {
        type = types.submodule({
          options = {
            minimum-level = mkOption {
              type = types.str;
              default = defaults.logging.minimum-level;
              description = "The minimum level for logging to control verbosity.";
            };
            format = mkOption {
              type = types.str;
              default = defaults.logging.format;
              description = "The log format. One of: Fancy, Plain, Json or Logfmt";
            };
            levels = mkOption {
              type = types.attrs;
              default = defaults.logging.levels;
              description = "Set of logger and their levels";
            };
          };
        });
        default = defaults.logging;
        description = "Settings for logging";
      };

      response-timeout = mkOption {
        type = types.str;
        default = defaults.response-timeout;
        description = ''
          The time from receiving a request until the first line of the
          response is rendered. When uploading big chunks on slow
          connections, this may have to be increased (or the
          `webapp.chunk-size' decreased).
        '';
      };

      alias-member-enabled = mkOption {
        type = types.bool;
        default = defaults.alias-member-enabled;
        description = "Enable/disable the alias-member feature.";
      };

      webapp = mkOption {
        type = types.submodule({
          options = {
            app-name = mkOption {
              type = types.str;
              default = defaults.webapp.app-name;
              description = "This is shown in the top right corner of the web application";
            };
            app-logo = mkOption {
              type = types.str;
              default = defaults.webapp.app-logo;
              description = ''
                The login and register page displays a logo image, by default
                the Sharry logo. This can be changed here. It needs to be an URL
                to an image.
              '';
            };
            app-logo-dark = mkOption {
              type = types.str;
              default = defaults.webapp.app-logo-dark;
              description = ''
                The login and register page displays a logo image, by default
                the Sharry logo. This can be changed here. It needs to be an URL
                to an image. This url is used in dark mode.
              '';
            };
            app-icon = mkOption {
              type = types.str;
              default = defaults.webapp.app-icon;
              description = "The icon next to the app-name. Needs to be an URL to a image.";
            };
            app-icon-dark = mkOption {
              type = types.str;
              default = defaults.webapp.app-icon-dark;
              description = "The icon next to the app-name for dark mode. Needs to be an URL to a image.";
            };
            app-footer = mkOption {
              type = types.str;
              default = defaults.webapp.app-footer;
              description = ''
                This is markdown that is inserted as the footer on each page in
                the ui. If left empty, a link to the project is rendered.
              '';
            };
            app-footer-visible = mkOption {
              type = types.bool;
              default = defaults.webapp.app-footer-visible;
              description = ''
                Whether to display the footer on each page in the ui. Set it to
                false to hide it.
              '';
            };

            welcome-message = mkOption {
              type = types.str;
              default = defaults.webapp.welcome-message;
              description = ''
                The login page can display a welcome message that is readable by
                everyone. The text is processed as markdown.
              '';
            };
            chunk-size = mkOption {
              type = types.str;
              default = defaults.webapp.chunk-size;
              description = ''
                Chunk size used for one request. The server will re-chunk the
                stream into smaller chunks. But the client can transfer more in
                one requests, resulting in faster uploads.

                You might need to adjust this value depending on your setup. A
                higher value usually means faster uploads.
              '';
            };
            retry-delays = mkOption {
              type = types.listOf types.int;
              default = defaults.webapp.retry-delays;
              description = ''
                Number of milliseconds the client should wait before doing a new
                upload attempt after something failed. The length of the array
                denotes the number of retries.
              '';
            };
            auth-renewal = mkOption {
              type = types.str;
              default = defaults.webapp.auth-renewal;
              description = ''
                The interval a new authentication token is retrieved. This must
                be at least 30s lower than `backend.auth.session-valid'.
              '';
            };
            default-language = mkOption {
              type = types.str;
              default = defaults.webapp.default-language;
              description = ''
                The ISO-3166-1 code of the default language to use. If a invalid
                code is given (or one where no language is available), it falls
                back to "gb".
              '';
            };
            initial-page = mkOption {
              type = types.str;
              default = defaults.webapp.initial-page;
              description = "The initial page after login. One of: home, uploads, share";
            };
            default-validity = mkOption {
              type = types.str;
              default = defaults.webapp.default-validity;
              description = "The default validity to use in the gui.";
            };
            initial-theme = mkOption {
              type = types.str;
              default = defaults.webapp.initial-theme;
              description = "The theme to use initially. One of 'light' or 'dark'.";
            };
            oauth-auto-redirect = mkOption {
              type = types.bool;
              default = defaults.webapp.oauth-auto-redirect;
              description = "Whether to immediately redirect to the single configured oauth provider.";
            };
          };
        });
        default = defaults.webapp;
        description = "Settings regarding the web ui.";
      };

      backend = mkOption {
        type = types.submodule({
          options = {
            auth = mkOption {
              type = types.submodule({
                options = {
                  server-secret= mkOption {
                    type = types.str;
                    default = defaults.backend.auth.server-secret;
                    description = ''
                      The secret for this server that is used to sign the authenicator
                      tokens. You can use base64 or hex strings (prefix with b64: and
                      hex:, respectively). Otherwise the strings utf-8 bytes are used.
                    '';
                  };
                  session-valid = mkOption {
                    type = types.str;
                    default = defaults.backend.auth.session-valid;
                    description = ''
                      How long an authentication token is valid. The web application
                      will get a new one periodically.
                    '';
                  };
                  fixed = mkOption {
                    type = types.submodule({
                      options = {
                        enabled = mkOption {
                          type = types.bool;
                          default = defaults.backend.auth.fixed.enabled;
                          description = "Whether to enable this login module";
                        };
                        user = mkOption {
                          type = types.str;
                          default = defaults.backend.auth.fixed.user;
                          description = "The username";
                        };
                        password = mkOption {
                          type = types.str;
                          default = defaults.backend.auth.fixed.password;
                          description = "The plain-text password";
                        };
                        order = mkOption {
                          type = types.int;
                          default = defaults.backend.auth.fixed.order;
                          description = "The order relative to the other login modules.";
                        };
                      };
                    });
                    default = defaults.backend.auth.fixed;
                    description = ''
                      A fixed login module simply checks the username and password
                      agains the information provided here. This only applies if the
                      user matches, otherwise the next login module is tried.
                    '';
                  };
                  http = mkOption {
                    type = types.submodule({
                      options = {
                        enabled = mkOption {
                          type = types.bool;
                          default = defaults.backend.auth.http.enabled;
                          description = "Whether to enable this login module";
                        };
                        order = mkOption {
                          type = types.int;
                          default = defaults.backend.auth.http.order;
                          description = "The order relative to the other login modules.";
                        };
                        url = mkOption {
                          type = types.str;
                          default = defaults.backend.auth.http.url;
                          description = "The url to use";
                        };
                        method = mkOption {
                          type = types.str;
                          default = defaults.backend.auth.http.method;
                          description = "The http method to use";
                        };
                        body = mkOption {
                          type = types.str;
                          default = defaults.backend.auth.http.body;
                          description = "The request body if method is POST";
                        };
                        content-type = mkOption {
                          type = types.str;
                          default = defaults.backend.auth.http.content-type;
                          description = "The content type of the request body";
                        };
                      };
                    });
                    default = defaults.backend.auth.http;
                    description = ''
                      The http authentication module sends the username and password
                      via a HTTP request and uses the response to indicate success or
                      failure.

                      If the method is POST, the `body' is sent with the request and
                      the `content-type' is used.
                    '';
                  };
                  http-basic = mkOption {
                    type = types.submodule({
                      options = {
                        enabled = mkOption {
                          type = types.bool;
                          default = defaults.backend.auth.http-basic.enabled;
                          description = "Whether to enable this login module";
                        };
                        order = mkOption {
                          type = types.int;
                          default = defaults.backend.auth.http-basic.order;
                          description = "The order relative to the other login modules.";
                        };
                        url = mkOption {
                          type = types.str;
                          default = defaults.backend.auth.http-basic.url;
                          description = "The url to use";
                        };
                        method = mkOption {
                          type = types.str;
                          default = defaults.backend.auth.http-basic.method;
                          description = "The http method to use";
                        };
                      };
                    });
                    default = defaults.backend.auth.http-basic;
                    description = ''
                      Use HTTP Basic authentication. An Authorization header using
                      the Basic scheme is created and the request is send to the
                      given url. The response body will be ignored, only the status
                      is inspected.
                    '';
                  };
                  command = mkOption {
                    type = types.submodule({
                      options = {
                        enabled = mkOption {
                          type = types.bool;
                          default = defaults.backend.auth.command.enabled;
                          description = "Whether to enable this login module";
                        };
                        order = mkOption {
                          type = types.int;
                          default = defaults.backend.auth.command.order;
                          description = "The order relative to the other login modules.";
                        };
                        program = mkOption {
                          type = types.listOf types.str;
                          default = defaults.backend.auth.command.program;
                          description = "The executable and its arguments. Allows replacements for user and password.";
                        };
                        success = mkOption {
                          type = types.int;
                          default = defaults.backend.auth.command.success;
                          description = "The return code to indicate success";
                        };
                      };
                    });
                    default = defaults.backend.auth.command;
                    description = ''
                      The command authentication module runs an external command
                      giving it the username and password. The return code indicates
                      success or failure.
                    '';
                  };
                  internal = mkOption {
                    type = types.submodule({
                      options = {
                        enabled = mkOption {
                          type = types.bool;
                          default = defaults.backend.auth.internal.enabled;
                          description = "Whether to enable this login module";
                        };
                        order = mkOption {
                          type = types.int;
                          default = defaults.backend.auth.internal.order;
                          description = "The order relative to the other login modules.";
                        };
                      };
                    });
                    default = defaults.backend.auth.internal;
                    description = ''
                      The authentication module checks against the internal database.
                    '';
                  };
                  oauth = mkOption {
                    type = types.listOf (types.submodule {
                      options =
                        let d = builtins.head defaults.backend.auth.oauth;
                        in
                        {
                        enabled = mkOption {
                          type = types.bool;
                          default = d.enabled;
                          description = "Whether to enable this login module";
                        };
                        id = mkOption {
                          type = types.str;
                          default = d.id;
                          description = "A unique id that is part of the url";
                        };
                        name = mkOption {
                          type = types.str;
                          default = d.name;
                          description = "A name that is displayed inside the button on the login screen";
                        };
                        icon = mkOption {
                          type = types.str;
                          default = d.icon;
                          description = "A fontawesome icon name for the button";
                        };
                        authorize-url = mkOption {
                          type = types.str;
                          default = d.authorize-url;
                          description = ''
                            The url of the provider where the user can login and grant the
                            permission to retrieve the user name.
                          '';
                        };
                        token-url = mkOption {
                          type = types.str;
                          default = d.token-url;
                          description = ''
                            The url used to obtain a bearer token using the
                            response from the authentication above. The response from
                            the provider must be json or url-form-encdode.
                          '';
                        };
                        user-url = mkOption {
                          type = types.str;
                          default = d.user-url;
                          description = ''
                            The url to finalyy retrieve user information – only JSON responses
                             are supported.
                          '';
                        };
                        user-id-key = mkOption {
                          type = types.str;
                          default = d.user-id-key;
                          description = ''
                            The name of the field in the json response denoting the user name.
                          '';
                        };
                        user-email-key = mkOption {
                          type = types.nullOr types.str;
                          default = d.user-email-key;
                          description = ''
                            The name of the field in the json response denoting the users email."
                          '';
                        };
                        client-id = mkOption {
                          type = types.str;
                          default = d.client-id;
                          description = "Your client-id as given by the provider.";
                        };
                        client-secret = mkOption {
                          type = types.str;
                          default = d.cient-secret;
                          description = "Your client-secret as given by the provider.";
                        };
                      };
                    });
                    default = defaults.backend.auth.oauth;
                    description = ''
                      Uses OAuth2 "Code-Flow" for authentication against a
                      configured provider.

                      A provider (like Github or Google for example) must be
                      configured correctly for this to work. Each element in the array
                      results into a button on the login page.

                      Examples for Github and Google are provided below. You need to
                      setup an “application” to obtain a client_secret and clien_id.
                    '';
                  };
                };
              });
              default = defaults.backend.auth;
              description = "Authentication settings";
            };

            share = mkOption {
              type = types.submodule({
                options = {
                  chunk-size = mkOption {
                    type = types.str;
                    default = defaults.backend.share.chunk-size;
                    description = "When storing binary data use chunks of this size.";
                  };
                  max-size = mkOption {
                    type = types.str;
                    default = defaults.backend.share.max-size;
                    description = "Maximum size of a share.";
                  };
                  max-validity = mkOption {
                    type = types.str;
                    default = defaults.backend.share.max-validity;
                    description = "Maximum validity for uploads.";
                  };

                  database-domain-checks = mkOption {
                    type = types.listOf (types.submodule {
                      options =
                        let
                          d = builtins.head defaults.backend.share.database-domain-checks;
                        in
                          {
                            enabled = mkOption {
                              type = types.bool;
                              default = d.enabled;
                              description = "Whether to enable this login module";
                            };
                            native = mkOption {
                              type = types.str;
                              default = d.native;
                              description = "The native database error message substring.";
                            };
                            message = mkOption {
                              type = types.str;
                              default = d.message;
                              description = "The user message to show in this error case.";
                            };
                          };
                    });
                    default = defaults.backend.share.database-domain-checks;
                    description = ''
                     Allows additional database checks to be translated into some
                     meaningful message to the user.

                     This config is used when inspecting database error messages.
                     If the error message from the database contains the defined
                     `native` part, then the server returns a 422 with the error
                     messages given here as `message`.

                     See issue https://github.com/eikek/sharry/issues/255 – the
                     example is a virus check via a postgresql extension "snakeoil".
                    '';
                  };
                };
              });
              default = defaults.backend.share;
              description = "Settings for shares";
            };

            jdbc = mkOption {
              type = types.submodule ({
                options = {
                  url = mkOption {
                    type = types.str;
                    default = defaults.backend.jdbc.url;
                    description = ''
                      The URL to the database. By default a file-based database is
                      used. It should also work with mariadb and postgresql.

                      Examples:
                         "jdbc:mariadb://192.168.1.172:3306/docspell"
                         "jdbc:postgresql://localhost:5432/docspell"
                         "jdbc:h2:///home/dbs/docspell.db;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;AUTO_SERVER=TRUE"

                    '';
                  };
                  user = mkOption {
                    type = types.str;
                    default = defaults.backend.jdbc.user;
                    description = "The user name to connect to the database.";
                  };
                  password = mkOption {
                    type = types.str;
                    default = defaults.backend.jdbc.password;
                    description = "The password to connect to the database.";
                  };
                };
              });
              default = defaults.backend.jdbc;
              description = "Database connection settings";
            };

            cleanup = mkOption {
              type = types.submodule({
                options = {
                  enabled = mkOption {
                    type = types.bool;
                    default = defaults.backend.cleanup.enabled;
                    description = ''
                      Whether to enable the upload cleanup job that periodically
                      removes invalid uploads
                    '';
                  };
                  interval = mkOption {
                    type = types.str;
                    default = defaults.backend.cleanup.interval;
                    description = "The interval for the cleanup job";
                  };
                  invalid-age = mkOption {
                    type = types.str;
                    default = defaults.backend.cleanup.invalid-age;
                    description = "Age of invalid uploads to get collected by cleanup job";
                  };
                };
              });
              default = defaults.backend.cleanup;
              description = "Settings for the periodic cleanup job.";
            };

            signup = mkOption {
              type = types.submodule ({
                options = {
                  mode = mkOption {
                    type = types.str;
                    default = defaults.backend.signup.mode;
                    description = ''
                      The mode defines if new users can signup or not. It can have
                      three values:

                      - open: every new user can sign up
                      - invite: new users can sign up only if they provide a correct
                        invitation key. Invitation keys can be generated by the
                        server.
                      - closed: signing up is disabled.
                    '';
                  };
                  invite-password = mkOption {
                    type = types.str;
                    default = defaults.backend.signup.invite-password;
                    description = ''
                      A password that is required when generating invitation keys.
                      This is more to protect against accidentally creating
                      invitation keys. Generating such keys is only permitted to
                      admin users.
                    '';
                  };
                  invite-time = mkOption {
                    type = types.str;
                    default = defaults.backend.signup.invite-time;
                    description = ''
                      If mode == 'invite', this is the period an invitation token is
                      considered valid.
                    '';
                  };
                };
              });
              default = defaults.backend.signup;
              description = "Registration settings. These accounts are checked by the 'internal' auth module.";
            };
            mail = mkOption {
              type = types.submodule({
                options = {
                  enabled = mkOption {
                    type = types.bool;
                    default = defaults.backend.mail.enabled;
                    description = ''
                      Enable/Disable the mail feature.

                      If it is disabled, the server will not send mails, including
                      notifications.

                      If enabled, explicit SMTP settings must be provided.
                    '';
                  };
                  smtp = mkOption {
                    type = types.submodule({
                      options = {
                        host = mkOption {
                          type = types.str;
                          default = defaults.backend.mail.smtp.host;
                          description = "Host or IP of the SMTP server.";
                        };
                        port = mkOption {
                          type = types.int;
                          default = defaults.backend.mail.smtp.port;
                          description = "Port of the SMTP server.";
                        };
                        user = mkOption {
                          type = types.str;
                          default = defaults.backend.mail.smtp.user;
                          description = ''
                            User to authenticate at the server. If the user
                            is empty, mails are sent without authentication.
                          '';
                        };
                        password = mkOption {
                          type = types.str;
                          default = defaults.backend.mail.smtp.password;
                          description = "Password for authentication at the server.";
                        };
                        ssl-type = mkOption {
                          type = types.str;
                          default = defaults.backend.mail.smtp.ssl-type;
                          description = "One of: none, starttls, ssl";
                        };
                        check-certificates = mkOption {
                          type = types.bool;
                          default = defaults.backend.mail.smtp.check-certificates;
                          description = ''In case of self-signed certificates or other problems like
                             that, checking certificates can be disabled.
                          '';
                        };
                        timeout = mkOption {
                          type = types.str;
                          default = defaults.backend.mail.smtp.timeout;
                          description = "Timeout for mail commands.";
                        };
                        default-from = mkOption {
                          type = types.str;
                          default = defaults.backend.mail.smtp.default-from;
                          description = ''
                            The default mail address used for the `From' field.

                            If left empty, the e-mail address of the current user is used.
                          '';
                        };
                        list-id = mkOption {
                          type = types.str;
                          default = defaults.backend.mail.smtp.list-id;
                          description = ''
                            When creating mails, the List-Id header is set to this value.

                            This helps identifying these mails in muas. If it is empty,
                            the header is not set.
                          '';
                        };
                      };
                    });
                    default = defaults.backend.mail.smtp;
                    description = "SMTP Settings";
                  };
                  templates = mkOption {
                    type = types.submodule({
                      options = {
                        download = mkOption {
                          type = types.submodule({
                            options = {
                              subject = mkOption {
                                type = types.str;
                                default = defaults.backend.mail.templates.download.subject;
                                description = "The mail subject";
                              };
                              body = mkOption {
                                type = types.str;
                                default = defaults.backend.mail.templates.download.body;
                                description = "The mail body";
                              };
                            };
                          });
                          default = defaults.backend.mail.templates.download;
                          description = "The template used when sending mails for new shares.";
                        };
                        alias = mkOption {
                          type = types.submodule({
                            options = {
                              subject = mkOption {
                                type = types.str;
                                default = defaults.backend.mail.templates.alias.subject;
                                description = "The mail subject";
                              };
                              body = mkOption {
                                type = types.str;
                                default = defaults.backend.mail.templates.alias.body;
                                description = "The mail body";
                              };
                            };
                          });
                          default = defaults.backend.mail.templates.alias;
                          description = "The templates used when sending alias links.";
                        };
                        upload-notify = mkOption {
                          type = types.submodule({
                            options = {
                              subject = mkOption {
                                type = types.str;
                                default = defaults.backend.mail.templates.upload-notify.subject;
                                description = "The mail subject";
                              };
                              body = mkOption {
                                type = types.str;
                                default = defaults.backend.mail.templates.upload-notify.body;
                                description = "The mail body";
                              };
                            };
                          });
                          default = defaults.backend.mail.templates.upload-notify;
                          description = "Template used when sending notifcation mails.";
                        };
                      };
                    });
                    default = defaults.backend.mail.templates;
                    description = "Mail templates";
                  };
                };
              });
              default = defaults.backend.mail;
              description = "Mail settings";
            };
          };
        });
        default = defaults.backend;
        description = "Settings regarding the server backend";
      };
    };
  };

  ## implementation
  config = mkIf config.services.sharry.enable {

    users.users."${user}" = mkIf (cfg.runAs == null) {
      name = user;
      isSystemUser = true;
      description = "Sharry user";
      group = "sharry";
    };
    users.groups = mkIf (cfg.runAs == null) {
      sharry = {};
    };

    systemd.services.sharry =
    let
      cmd = "${pkgs.sharry}/bin/sharry-restserver ${sharryConf}";
    in
    {
      description = "Sharry Rest Server";
      after = [ "networking.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.gawk ];

      script =
        "${pkgs.su}/bin/su -s ${pkgs.bash}/bin/sh ${user} -c \"${cmd}\"";
    };
  };
}
