module Messages.UploadPage exposing
    ( Texts
    , de
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


de : Texts
de =
    { yourShares = "Deine Freigaben"
    , newShare = "Neue Freigabe"
    , search = "Suche…"
    , shareTable = Messages.ShareTable.de
    }
