module Messages.AliasTable exposing
    ( Texts
    , de
    , fr
    , gb
    , ja
    , cz
    , es
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


es : Texts
es =
    { name = "Nombre"
    , enabled = "Habilitado"
    , validity = "Validez"
    , created = "Creado"
    , edit = "Editar"
    , show = "Mostrar"
    , owner = "Propietario"
    , validityField = Messages.ValidityField.es
    , dateTime = Messages.DateFormat.formatDateTime Language.Spanish
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


ja : Texts
ja =
    { name = "受信箱名"
    , enabled = "有効"
    , validity = "有効期限"
    , created = "作成日時"
    , edit = "編集"
    , show = "表示"
    , owner = "所有者"
    , validityField = Messages.ValidityField.ja
    , dateTime = Messages.DateFormat.formatDateTime Language.Japanese
    }

cz : Texts
cz =
    { name = "Jméno"
    , enabled = "Povoleno"
    , validity = "Platnost"
    , created = "Vytvořen"
    , edit = "Upravit"
    , show = "Zobrazit"
    , owner = "Vlastník"
    , validityField = Messages.ValidityField.cz
    , dateTime = Messages.DateFormat.formatDateTime Language.Czech
    }
