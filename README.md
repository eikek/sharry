<img align="left"
     src="https://raw.githubusercontent.com/eikek/sharry/master/artwork/icon.png"
     height="120px"
     style="padding-right: 20px">

[![Build Status](https://travis-ci.org/eikek/sharry.svg?branch=master)](https://travis-ci.org/eikek/sharry)
[![Scala Steward badge](https://img.shields.io/badge/Scala_Steward-helping-blue.svg?style=flat&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA4AAAAQCAMAAAARSr4IAAAAVFBMVEUAAACHjojlOy5NWlrKzcYRKjGFjIbp293YycuLa3pYY2LSqql4f3pCUFTgSjNodYRmcXUsPD/NTTbjRS+2jomhgnzNc223cGvZS0HaSD0XLjbaSjElhIr+AAAAAXRSTlMAQObYZgAAAHlJREFUCNdNyosOwyAIhWHAQS1Vt7a77/3fcxxdmv0xwmckutAR1nkm4ggbyEcg/wWmlGLDAA3oL50xi6fk5ffZ3E2E3QfZDCcCN2YtbEWZt+Drc6u6rlqv7Uk0LdKqqr5rk2UCRXOk0vmQKGfc94nOJyQjouF9H/wCc9gECEYfONoAAAAASUVORK5CYII=)](https://scala-steward.org)

# Sharry

Sharry allows to share files with others in a simple way. It is a
self-hosted web application. The basic concept is: upload files and get
a url back that can then be shared.

<a href="https://xkcd.com/949/">
  <img height="400" align="right" style="float:right" src="https://imgs.xkcd.com/comics/file_transfer.png">
</a>

## How it works

### Authenticated users → others

Authenticated users can upload their files on a web site together with
an optional password and a time period. The time period defines how long
the file is available for download. Then a public URL is generated that
can be shared, e.g. via email.

The download page is hard to guess, but open to everyone.

### Others → Authenticated users

Each registered user can maintain alias pages. An alias page is behind
a “hard-to-guess” URL (just like the download page) and allows
everyone to upload files to the corresponding user. The form does not
allow to specify a password or validation period, but a description
can be given. The user belonging to the alias can be notified via
email. Alias pages can be disabled or deleted any time.

## Install

- Install the [provided](https://github.com/eikek/sharry/releases)
  `deb` file at your debian based system.
- Download [provided](https://github.com/eikek/sharry/releases) zip
  file and run the script in `bin/`, as [described
  here](https://eikek.github.io/sharry/doc/quickstart#quickstart).
- Using the [nix](https://nixos.org/nix) package manager as [described
  here](https://eikek.github.io/sharry/doc/nix). A a NixOS module is
  available, too.
- Using Docker, as [described
  here](https://eikek.github.io/sharry/doc/quickstart#quickstart-with-docker).

## Documentation

Please see the [documentation site](https://eikek.github.io/sharry).


## Screenshots

![screenshot-1](https://raw.githubusercontent.com/eikek/sharry/master/modules/microsite/docs/screenshots/Selection_226.png)
![screenshot-2](https://raw.githubusercontent.com/eikek/sharry/master/modules/microsite/docs/screenshots/Selection_230.png)
![screenshot-3](https://raw.githubusercontent.com/eikek/sharry/master/modules/microsite/docs/screenshots/Selection_235.png)
![screenshot-4](https://raw.githubusercontent.com/eikek/sharry/master/modules/microsite/docs/screenshots/mobile_02.png)
![screenshot-5](https://raw.githubusercontent.com/eikek/sharry/master/modules/microsite/docs/screenshots/mobile_03.png)
![screenshot-6](https://raw.githubusercontent.com/eikek/sharry/master/modules/microsite/docs/screenshots/mobile_04.png)

## Contributions/Support

Feedback and other contributions are very welcome! You can [open an
issue](https://github.com/eikek/sharry/issues/new) for questions,
problems and other feedback; or make a mail to `eikek [at] posteo.de`.
I'll try to answer in time.

If you find this project any useful and want to support it via other
means, giving a :star: is always encouraging and much appreciated. You
can also support activity by donating via
[liberapay](https://liberapay.com/eikek/) or
[paypal](https://paypal.me/eikek0).

Thank you so much!


## Technical

Sharry implements the [tus](https://tus.io) protocol and the webapp
uses it to send files to the backend server. This allows to send even
large files reliably through http. For example, even if the connection
drops in the middle of an upload and you upload the same file again
later, it starts the upload process from the last received chunk of
data.

The backend is written in Scala using a pure functional style on top
of great [typelevel](https://typelevel.org/) libraries like
[cats](https://typelevel.org/cats/) and
[fs2](https://github.com/typelevel/fs2). The frontend is written in
[elm](https://elm-lang.org).


## License

This project is distributed under the
[GPLv3+](https://spdx.org/licenses/GPL-3.0-or-later.html)
