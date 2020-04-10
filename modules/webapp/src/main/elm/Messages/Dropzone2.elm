module Messages.Dropzone2 exposing
    ( Dropzone2
    , gb
    )


type alias Dropzone2 =
    { dropHere : String
    , filesSelected : String
    , or : String
    , selectFiles : String
    }


gb : Dropzone2
gb =
    { dropHere = "Drop files here"
    , filesSelected = " files selected ("
    , or = "Or"
    , selectFiles = "Select Files ..."
    }
