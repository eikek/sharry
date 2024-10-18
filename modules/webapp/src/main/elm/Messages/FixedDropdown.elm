module Messages.FixedDropdown exposing
    ( Texts
    , de
    , gb
    , fr
    , ja
    , cz
    , es
    )


type alias Texts =
    { select : String
    }


es : Texts
es =
    { select = "Seleccionar…"
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

cz : Texts
cz =
    { select = "Vybrat…"
    }

