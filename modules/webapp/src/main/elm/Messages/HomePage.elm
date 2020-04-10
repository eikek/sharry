module Messages.HomePage exposing
    ( Texts
    , gb
    )


type alias Texts =
    { createShare : String
    , viewShares : String
    , documentation : String
    }


gb : Texts
gb =
    { createShare = "Create Share"
    , viewShares = "View Shares"
    , documentation = "Documentation"
    }
