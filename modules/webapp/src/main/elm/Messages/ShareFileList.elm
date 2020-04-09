module Messages.ShareFileList exposing
    ( ShareFileList
    , gb
    )

import Messages.YesNoDimmer exposing (YesNoDimmer)


type alias ShareFileList =
    { previewNotSupported : String
    , downloadToDisk : String
    , viewInBrowser : String
    , deleteFile : String
    , fileIsIncomplete : String
    , tryUploadAgain : String
    , yesNo : YesNoDimmer
    }


gb : ShareFileList
gb =
    { previewNotSupported = "Preview not supported"
    , downloadToDisk = "Download to disk"
    , viewInBrowser = "View in browser"
    , deleteFile = "Delete the file."
    , fileIsIncomplete = "The file is incomplete ("
    , tryUploadAgain = "%). Try uploading again."
    , yesNo = Messages.YesNoDimmer.gb
    }
