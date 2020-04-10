module Messages.YesNoDimmer exposing
    ( Texts
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
