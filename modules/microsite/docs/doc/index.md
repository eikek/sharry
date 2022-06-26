---
layout: docs
title: Documentation
---

# Sharry

Sharry allows to share files with others in a simple way. It is a
self-hosted web application. The basic concept is: upload files and get
a url back that can then be shared.

<a href="https://xkcd.com/949/"><img height="400" align="right" style="float:right" src="https://imgs.xkcd.com/comics/file_transfer.png"></a>

## How it works

### Authenticated users → others

Authenticated users can upload their files on a web site together with
an optional password and a time period. The time period defines how long
the file is available for download. Then a public URL is generated that
can be shared, e.g. via email, with everyone.

While the download page is hard to guess, everyone who knows it can
access the files.

### Others → Authenticated users

Anonymous can send files to registered users. Each registered user can
maintain *alias pages*. An alias page is also behind a “hard-to-guess”
URL (just like the download page) and allows everyone to upload files
to the corresponding user. The user belonging to the alias can be
notified via email.

## Features

- *Both ways:* Receive and send files to/from anonymous users.
- *Integration:* Sharry aims to be easy to integrate in other
  environments.
  - Authentication: There are many ways to authenticate users from
    different sources and/or use internal user management.
  - [REST Api](rest) exposing all the features, making it available for
    scripts.
- *Reliable up- and downloads*
  - Uploads: While the server accepts standard multipart requests, it
    also supports the [tus protocol](https://tus.io) allowing for
    resumable uploads. In case network goes down in the middle of
    uploading a large file, simply upload the same file again and it
    will start where it left off.
  - Downloads: Using ETag and [range
    requests](https://en.wikipedia.org/wiki/Byte_serving) allows the
    clients (the browser, mostly) to cache files and to download only
    portions of files. This makes it possible to efficiently view
    videos in the browser (being able to click into the timeline).
- *Web client* for managing and accessing shares.
- *Signup* Let all users create new accounts, only invited ones or none.
- *Restrict public download pages* using three properties: a lifetime, a
  password (acting as a second secret) and download-limit.
- *Periodic cleanup* will remove expired shares
- *Send E-Mails* from within Sharry (if configured)
- *DBMS* Data is stored in a relational database, supporting
  [PostgreSQL](https://postgresql.org), [MariaDB](https://mariadb.org)
  and [H2](https://h2database.com) (h2 is an in-process db, not
  requiring a separate database server).
- Files can be stored in the database as well. Other options are the
  filesystem or an S3 compatible object storage

## License

This project is distributed under the
[GPLv3+](https://spdx.org/licenses/GPL-3.0-or-later.html)
