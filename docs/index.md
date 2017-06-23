# Sharry Manual

This is the user manual for sharry `{{version}}`.


## Introduction

Sharry is a [REST](https://en.wikipedia.org/wiki/Representational_state_transfer) web server and a web application that is
designed to share files with others.

The basic idea is the same as with many other such tools: Upload files
via a web site to a server. Then a unique and “hard to guess” url is
created that can be used by anyone to download the files.

In contrast to some other solutions, sharry _does_ use authentication
and manages accounts in order to restrict who can upload files;
i.e. it is not a one-click file sharing tool. With sharry every
registered user controls who can upload files. First, a user can
upload any files and share the resulting url with everyone
else. Second, a user can decide to create a page that is also a “hard
to guess” url where anyone can upload files to that specific
user. Thus a registered user can share files with anyone and anyone
can share files with registered users.

Sharry is distributed under the [GPLv3](http://www.gnu.org/licenses/gpl-3.0.html) license. The source code is
on [github](https://github.com/eikek/sharry).

Feedback is always very welcome, use whatever channel you like; for
example github issues, email or pull request.


## Contents

1. [Concepts](concepts.md)
2. [Install](install.md)
3. [Configuration](configuration.md)
4. [Web application](webapp.md)
