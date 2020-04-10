module Messages.AliasTable exposing
    ( Texts
    , gb
    )


type alias Texts =
    { name : String
    , enabled : String
    , validity : String
    , created : String
    }


gb : Texts
gb =
    { name = "Name"
    , enabled = "Enabled"
    , validity = "Validity"
    , created = "Created"
    }
