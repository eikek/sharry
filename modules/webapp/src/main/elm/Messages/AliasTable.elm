module Messages.AliasTable exposing
    ( AliasTable
    , gb
    )


type alias AliasTable =
    { name : String
    , enabled : String
    , validity : String
    , created : String
    }


gb : AliasTable
gb =
    { name = "Name"
    , enabled = "Enabled"
    , validity = "Validity"
    , created = "Created"
    }
