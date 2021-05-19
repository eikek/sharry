module Messages.AliasTable exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Language
import Messages.DateFormat
import Messages.ValidityField


type alias Texts =
    { name : String
    , enabled : String
    , validity : String
    , created : String
    , edit : String
    , show : String
    , owner : String
    , validityField : Messages.ValidityField.Texts
    , dateTime : Int -> String
    }


gb : Texts
gb =
    { name = "Name"
    , enabled = "Enabled"
    , validity = "Validity"
    , created = "Created"
    , edit = "Edit"
    , show = "Show"
    , owner = "Owner"
    , validityField = Messages.ValidityField.gb
    , dateTime = Messages.DateFormat.formatDateTime Language.English
    }


de : Texts
de =
    { name = "Name"
    , enabled = "Aktiv"
    , validity = "Gültigkeit"
    , created = "Erstellt"
    , edit = "Editieren"
    , show = "Anzeigen"
    , owner = "Eigentümer"
    , validityField = Messages.ValidityField.de
    , dateTime = Messages.DateFormat.formatDateTime Language.German
    }


fr : Texts
fr =
    { name = "Nom"
    , enabled = "Activé"
    , validity = "Validité"
    , created = "Créé"
    , edit = "Éditer"
    , show = "Show"
    , owner = "Owner"
    , validityField = Messages.ValidityField.fr
    , dateTime = Messages.DateFormat.formatDateTime Language.French
    }
