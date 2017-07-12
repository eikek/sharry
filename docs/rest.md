[Contents](index.md)

# Rest Api

All functionality is provided by the server via a rest interface. This
page sketches the current state – it is a work in progress.


## Authentication

Authentication is done via username and password. Upon successful
authentication, a cookie header is sent with the response which must
be used with all non-public requests.

The cookie is valid for a certain amount of time (15 minutes per
default). This time is reset on each request that requires the cookie.

-   `POST api/v1/auth/login`
    -   json body with username and password `{"user":"", "pass":""}`
    -   returns cookie when successful verified and account data without password
    -   returns 401 when verification fails
-   `POST api/v1/auth/cookie`
    -   checks the cookie header
    -   resets cookie time
-   `GET api/v1/auth/logout`
    -   removes cookie by sending an invalid one


## Accounts

Accounts can only managed by admin users, while the current user can
update its profile email and password (only if the user is not
externally authenticated).

-   `GET api/v1/accounts[?q=name]`
    -   admins only
    -   returns json list of accounts
    -   `q` allows to search for a name (simple substring search)
-   `GET api/v1/accounts/<name>`
    -   admins only
    -   get single account by name
-   `PUT api/v1/accounts`
    -   admins only
    -   expects json body with account data
    -   creates new account, fails if it exists
    -   password if encrypted if non-empty
-   `POST api/v1/accounts`
    -   admins only
    -   json body with account data
    -   modifies an account, 404 if not found
    -   password is encrypted if non-empty
    -   email is removed if empty
-   `POST api/v1/profile/email`
    -   update email of current user
    -   expects json body with full account data
-   `POST api/v1/profile/password`
    -   update password of current user
    -   expects json body with full account data


## Uploads

Uploads can either be created and deleted by authenticated users, or
via a `X-Sharry-Alias` header specifying a valid alias id.

To upload files, first create a new upload via `POST
api/v1/uploads`. Currently `id` must be non-existent, it can be some
random string. If this was successful, use the `POST
api/v1/upload-data` to upload the files in chunks. The `token` query
parameter is the `id` from the previous call.


-   `POST api/v1/uploads`
    -   json body `{id: String, description: String, validity: String,
        maxdownloads: Int, password: String}`
    -   creates a new upload, `id` must not exist
-   `DELETE api/v1/uploads/<id>`
    -   delete the upload with given id
    -   when deleting via the alias-header, it is only possible during
        a certain time window after uploading
-   `GET api/v1/uploads`
    -   list all uploads for current user
    -   json array of upload objects
-   `GET api/v1/uploads/<id>`
    -   get uploads with given id
    -   return json with upload object and all files
-   `GET api/v1/upload-publish/<id>`
    -   get a published upload by its public id
-   `POST api/v1/upload-publish/<id>`
    -   publish an upload by its private id
-   `POST api/v1/upload-unpublish/<id>`
    -   unpublish an upload given by its private id
-   `POST api/v1/upload-notify/<id>`
    -   schedules a notification mail for alias uploads
    -   `id` is the internal upload id
    -   is authorized by alias header only
    -   mail is scheduled in 30 seconds + deletion time (the time the
        user is allowed to delete/cancel an upload)
    -   can be used when an alias upload is done to notify the
        receiver of a new upload to his or her alias page
-   `GET api/v1/upload-data`
    -   checks whether a chunk is already uploaded
    -   query paramaters for `token: String, chunkNumber: Int,
        chunkSize: Int, currentChunkSize: Int, totalSize: Long,
        fileIdentifier: String, filename: String, totalChunks: Int`
    -   either `OK` (if the chunk exists) or `NoContent`
    -   token is the upload id
-   `POST api/v1/upload-data`
    -   upload a chunk of a file
    -   body is the chunkdata as `application/octet-stream` (not
        multipart)
    -   query paramaters for `token: String, chunkNumber: Int,
        chunkSize: Int, currentChunkSize: Int, totalSize: Long,
        fileIdentifier: String, filename: String, totalChunks: Int`
        are required to identify the chunk
    -   the `token` query parameter is the upload id; the
        `fileIdentifier` is some string identifying the file, the
        webapp uses the filename + file size, for example.

## Download Files

These routes are for downloading files of an upload. There are the
protected routes only accessible for authenticated users and the
public ones.

-   `GET api/v1/dl/file/<id>`
    -   download a specific file by its id
    -   allows byte ranges
-   `HEAD api/v1/dl/file/<id>`
    -   headers for a specific file by its id
-   `GET api/v1/dl/zip/<id>`
    -   download all files of an upload as zip
    -   doesn't allow byte ranges
    -   authentication required, access stats not updated
-   `GET dlp/file/<id>`
    -   download a file by its id only if the corresponding upload is public
    -   access stats are updated, authentication not required
-   `HEAD dlp/file/<id>`
    -   get headers for a file by its id only if upload is public
-   `GET dlp/zip`
    -   download all files of a public upload
    -   doesn't allow byte ranges
    -   authentication not required
-   `POST api/v1/check-password/<id>`
    -   check the password for a download
    -   body is json `{"password": "xxx"}`
    -   authentication not required
    -   id is public id of an upload
    -   status `OK` with either error messages or empty list of
        messages
    -   attaches special cookie header with that password if
        successful (= empty message list); this cookie is used when
        downloading files that are password protected
    -   returns 404 if id doesn't match an updload


## Aliases

-   `POST api/v1/aliases`
    -   create a new alias
-   `POST api/v1/aliases/update`
    -   update existing alias
-   `GET api/v1/aliases`
    -   get list of aliases
-   `GET api/v1/aliases/<id>`
    -   get single alias by id
-   `DELETE api/v1/aliases/<id>`
    -   delete a single alias


## Mail

All mail features are only available to authenticated users.

-   `GET api/v1/mail/check?mail=email@domain`
    -   check a email address for validity
-   `POST api/v1/mail/send`
    -   sends an email (if configured correctly)
    -   json body `{"to": [], "subject":"", "text":""}`
    -   response is ok with json body `{"message":"", "success":[], "failed":[]}`
    -   message: some message explaining the result
    -   success: list of email addresses where mail has been successfully sent
    -   failed: list of email addresses and explanation where mail could not be sent
-   `GET api/v1/mail/download-template?url=&pass=&lang=`
    -   download a mail template from config file
    -   template is expanded with parameters
    -   `lang` and `pass` are optional parameters, `url` is required
    -   response is json `{"lang":"", "text":"", "subject":""}`
-   `GET api/v1/mail/alias-template`
    -   download a mail template from config file
    -   template is expanded with parameters
    -   `lang` and `pass` are optional parameters, `url` is required
    -   response is json `{"lang":"", "text":"", "subject":""}`


## Manual

Manual pages are not protected.

-   `GET manual/<rest>?mdLinkPrefix=`
    -   download a manual page (in markdown format) or manual resource
        files (like images)
    -   optional parameter `mdLinkPrefix`
        -   can be used to prefix all links to markdown files (other manual
            pages) with the given path
        -   the webapp uses this to prefix it with `#manual/` in order to
            let ajax requests do the navigation
        -   only applies to links to markdown files
