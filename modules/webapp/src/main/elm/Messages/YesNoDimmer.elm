module Messages.YesNoDimmer exposing
    ( Texts
    , de
    , gb
    )


type alias Texts =
    { message : String
    , confirmButton : String
    , cancelButton : String
    }


gb : Texts
gb =
    { message = "Delete this item permanently?"
    , confirmButton = "Yes, do it!"
    , cancelButton = "No"
    }


de : Texts
de =
    { message = "Dauerhaft entfernen?"
    , confirmButton = "Ja, bitte!"
    , cancelButton = "Nein"
    }
