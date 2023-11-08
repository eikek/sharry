module Messages.FixedDropdown exposing
    ( Texts
    , de
    , gb
    , fr
    , ja
    )


type alias Texts =
    { select : String
    }


gb : Texts
gb =
    { select = "Select…"
    }


de : Texts
de =
    { select = "Auswahl…"
    }

fr : Texts
fr =
    { select = "Selectionner…"
    }

ja : Texts
ja =
    { select = "選択…"
    }
