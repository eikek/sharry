# Command Line Client

Sharry provides a command line client for uploading/publishing
files. Managing aliases or user accounts must still be done using the
web interface.

## Getting it

### Download

There are prebuild binary files here:

- [Sharry Cli {{versionShort}}](https://eknet.org/main/projects/sharry/sharry-cli-{{versionShort}}.jar.sh)


### Building

You can build it from source. It requires Java >= 1.8 and
[Sbt](http://scala-sbt.org). Run

    sbt make-cli

in the source root. This will create an executable jar file in
`modules/cli/target/scala-2.12/sharry-cli_2.12-{{versionShort}}.jar.sh`. You
can link it to some shorter command, like `sharr` in your `$PATH`.

## Publishing files

The command `upload-files` or `publish-files` can be used to send
files to sharry. The former only uploads the files while the latter
also publishes them.

Here is an example:

    $ sharry publish-files --endpoint http://localhost:9090 --login admin --pass admin  ~/Downloads/*.mpg
    Prepare to upload 46 files (113.22M).
    Authenticating at http://localhost:9090
    Creating a new upload.
    100,00 |==========================================================| 56.61M/s
    Publishing upload.
    http://localhost:9090#uid=cH3wcZqnwv7QQPFQ8sRvm-o
    http://localhost:9090#id=JNDKvZahrw5wmcN9Mxc2jOdLfOrOnkyzB3Sco

The last url is the public url, if the upload is published. There are
options to specify properties for the upload.

You can pass everything to the command or use defaults from the config
file.

```
$ sharry --help
{{& cli-help}}
```

Since you can only upload files to an alias page or your own account
one of `--alias` or `--endpoint` (and `--login` and `--pass`) must be
specified. The `--alias` options wins if all are specified.

You can also run `sharry resume` without any options, then it tries to
resume an existing upload that has been cancelled.


## Publishing text

There is a special publish command for markdown files. The markdown
file is used for the description of the upload. All referenced local
files are added to the upload. The links in the markdown text are then
changed to reflect the uploaded files. So with this command you can
publish a markdown text together with its resources.

The same options apply as to the `publish` command, only
`--description` is ignored and only one file (in markdown format) can
be specified.

If you don't use markdown, there exist tools to convert your markup of
choice to markdown. For example [pandoc](http://pandoc.org/) works
great.


## Configuration

The config file is `$HOME/.config/sharry/cli.conf` and its format is,
like the one on the server, in
[HOCON](https://github.com/typesafehub/config#using-hocon-the-json-superset)
format. Please see the _Format_ section of [configuration manual
page](./configuration.md) for more details.

The config file can be used to set default values for certain options
(e.g. `--endpoint`, etc).

### Default Configuration

The following is the default configuration as shipped with sharry for
reference.

```
{{& default-cli-config}}
```
