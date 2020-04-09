module Messages.YesNoDimmer exposing
    ( YesNoDimmer
    , gb
    )


type alias YesNoDimmer =
    { message : String
    , confirmButton : String
    , cancelButton : String
    }


gb : YesNoDimmer
gb =
    { message = "Delete this item permanently?"
    , confirmButton = "Yes, do it!"
    , cancelButton = "No"
    }
