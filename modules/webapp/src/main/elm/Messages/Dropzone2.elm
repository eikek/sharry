module Messages.Dropzone2 exposing
    ( Texts
    , de
    , gb
    )


type alias Texts =
    { dropHere : String
    , filesSelected : String
    , or : String
    , selectFiles : String
    }


gb : Texts
gb =
    { dropHere = "Drop files here"
    , filesSelected = " files selected ("
    , or = "Or"
    , selectFiles = "Select Files ..."
    }


de : Texts
de =
    { dropHere = "Dateien hier reinziehen"
    , filesSelected = " Dateien ausgewählt ("
    , or = "Oder"
    , selectFiles = "Dateien wählen ..."
    }
