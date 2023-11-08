module Messages.UploadPage exposing
    ( Texts
    , de
    , gb
    , fr
    , ja
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

fr : Texts
fr =
    { yourShares = "Vos partages"
    , newShare = "Nouveau partage"
    , search = "Recherche…"
    , shareTable = Messages.ShareTable.fr
    }


ja : Texts
ja =
    { yourShares = "あなたの共有"
    , newShare = "共有の新規作成"
    , search = "検索…"
    , shareTable = Messages.ShareTable.ja
    }
