module Messages.AliasTable exposing
    ( Texts
    , de
    , gb
    , fr
    )

import Messages.ValidityField


type alias Texts =
    { name : String
    , enabled : String
    , validity : String
    , created : String
    , validityField : Messages.ValidityField.Texts
    }


gb : Texts
gb =
    { name = "Name"
    , enabled = "Enabled"
    , validity = "Validity"
    , created = "Created"
    , validityField = Messages.ValidityField.gb
    }


de : Texts
de =
    { name = "Name"
    , enabled = "Aktiv"
    , validity = "Gültigkeit"
    , created = "Erstellt"
    , validityField = Messages.ValidityField.de
    }

fr : Texts
fr =
    { name = "Nom"
    , enabled = "Activé"
    , validity = "Validité"
    , created = "Créé"
    , validityField = Messages.ValidityField.fr
    }
