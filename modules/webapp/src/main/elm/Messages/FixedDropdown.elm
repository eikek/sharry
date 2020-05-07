module Messages.FixedDropdown exposing
    ( Texts
    , de
    , gb
    , fr
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
