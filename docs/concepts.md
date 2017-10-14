[Contents](index.md)
{{=<< >>=}}

# Concepts

Sharry allows its users to share files with anyone else and it allows
them to receive files from anyone else.

The basic idea is simple: upload one or more files and get a unique
url to a public download page back. This url can be shared with
others. It is not protected, everyone can download the files.

In order to receive files from others, ”alias pages” can be
generated. These are unique urls that are associated to a registered
user. Anyone can upload files using this url and they will be visible
in the receiving user's upload list. Only the registered user who is
associated with that alias page can download the files.

That's all.

## Uploads

An “upload” is a set of files (and some meta data) that have been
uploaded to the sharry server. There are two states of an upload:
published or not published. If an upload has been published, it is
accessible through some public download page. The owner can decide
whether to publish a download or not at any time. If an upload is not
published only the owner can see it.

Uploading files is resumable. Files are transferred in chunks (default
256k) to the server. This way a broken download (e.g. due to a lost
connection) can be resumed and all chunks already uploaded are
skipped. Uploads can also be paused and resumed. This should maket it
more convenient to upload large files.

Downloads are similiar. They are transferred in chunks and range
requests (a.k.a. [byte serving](https://en.wikipedia.org/wiki/Byte_serving)) are supported. This lets you watch
large video files in the browser without downloading the whole file.

An upload can be given some properties:

- validity time span
- password
- description
- maximum downloads

They are explained below.


### validity time

Every upload has a validity time after which the uploaded files are
“expired”. Then the public download page is not visible anymore and
the files can't be downloaded from non-protected urls.

The files are there and the user that owns them still has access. They
are eventually removed by a cleanup job.


### Password

The files can be further protected by a password. The download page
requires this password in order to download the files.


### Description

You can add some text to an upload. The download page displays the
descrpition. The description can be [markdown](http://daring-fireball.net) and is converted to
HTML when being displayed.

The description text is further processed as a [mustache](http://mustache.github.io/mustache.5.html) template
and allows to refer to the attached files. You can access the
following properties of any uploaded file:

- `id`
- `filename`
- `url`
- `mimetype`
- `size`

The files are refered to by either `file_n` where `n` denotes the
first, second etc. file starting by 0 or by `fileid_<id>` where `id`
is the file-id that was specified when it was uploaded (it is chosen
by the client). So this would render the url of the first file:

```
{{#file_0}}{{url}}{{/file_0}}
```

or

```
{{file_0.url}}
```

or using the id:

```
{{fileid_6487425-DSC0100JPG.url}}
```

The web application uses the file size and the file name (without
dots) for the id, as show in the example above.

This makes it possible to embed files in the description, for example
to display an image file, you could write the following description:

```
![an image]({{fileid_6487425-DSCF0343JPG.url}})
```

There is also a `files` property that can be used to iterate through
all uploaded files. So this would render the id and url of all files:

```
{{#files}}
- {{id}}: {{url}}
{{/files}}
```


### Maximum Downloads

This setting restricts the number of accesses to the download
page. Despite the (bad) name, it doesn't restrict the number of
downloads of the single files. If the download page is accessed more
than this number, it will not work anymore.


## Alias Page

Alias pages are always associated to an registered user who generates
them as he or she wishes. An alias page allows anyone to upload files
to this specific user.

The upload form on alias pages is just a subset of the normal upload
form: it only allows to give a description. All other properties are
not allowed, because they don't make sense.
