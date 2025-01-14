module Messages.FixedDropdown exposing
    ( Texts
    , de
    , gb
    , fr
    , ja
    , cz
    , es
    , it
    )


type alias Texts =
    { select : String
    }

it : Texts
it =
    { select = "Seleziona…"
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

