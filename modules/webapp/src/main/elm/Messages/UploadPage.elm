module Messages.UploadPage exposing
    ( Texts
    , gb
    )

import Messages.ShareTable


type alias Texts =
    { yourShares : String
    , newShare : String
    , search : String
    , shareTable : Messages.ShareTable.Texts
    }


gb : Texts
gb =
    { yourShares = "Your Shares"
    , newShare = "New Share"
    , search = "Search…"
    , shareTable = Messages.ShareTable.gb
    }
