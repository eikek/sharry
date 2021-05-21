---
layout: docs
title: ShareX
permalink: doc/sharex
---

# {{ page.title }}

[ShareX](https://getsharex.com/) is a popular screenshot tool. Below
is a "custom upload" template to allow uploading screenshots to Sharry
from ShareX.


```
{
  "Version": "1.3.1",
  "DestinationType": "ImageUploader, TextUploader, FileUploader",
  "RequestMethod": "POST",
  "RequestURL": "https://your.sharry/api/v2/alias/upload",
  "Body": "MultipartFormData",
  "Headers": {
    "Sharry-Alias": "some-alias-id"
  },
  "FileFormName": "file[]",
  "URL": "https://your.sharry/app/upload/$json:id$"
}
```

You need to replace `http://your.sharry` with your sharry url and
specify some alias id, replacing `some-alias-id` in the example. The
[alias](webapp#alias-pages) id can be found at any alias page that you
have access to.
