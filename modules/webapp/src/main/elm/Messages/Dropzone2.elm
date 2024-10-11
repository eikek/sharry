module Messages.Dropzone2 exposing
    ( Texts
    , de
    , gb
    , fr
    , ja
    , cz
    , es
    )


type alias Texts =
    { dropHere : String
    , filesSelected : String
    , or : String
    , selectFiles : String
    }


es : Texts
es =
    { dropHere = "Suelta los archivos aquí"
    , filesSelected = " archivos seleccionados ("
    , or = "O"
    , selectFiles = "Seleccionar Archivos ..."
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

fr : Texts
fr =
    { dropHere = "Glisser des fichiers ici"
    , filesSelected = " fichiers sélectionnés ("
    , or = "Ou"
    , selectFiles = "Sélectionner des fichiers ..."
    }

ja : Texts
ja =
    { dropHere = "ここにファイルをドロップ"
    , filesSelected = " 選択ファイル ("
    , or = "または"
    , selectFiles = "ファイルを選択..."
    }

cz : Texts
cz =
    { dropHere = "Sem přetáhněte soubory"
    , filesSelected = " vybrané soubory ("
    , or = "nebo"
    , selectFiles = "vyberte soubory ..."
    }
