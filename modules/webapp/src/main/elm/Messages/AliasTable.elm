module Messages.AliasTable exposing
    ( Texts
    , applyZone
    , de
    , fr
    , gb
    , ja
    , cz
    , es
    , it
    , br
    )

import Language exposing (Language)
import Messages.DateFormat
import Messages.ValidityField
import Time


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

it : Texts
it =
    { name = "Nome"
    , enabled = "Abilitato"
    , validity = "Validità"
    , created = "Creazione"
    , edit = "Modifica"
    , show = "Visualizza"
    , owner = "Proprietario"
    , validityField = Messages.ValidityField.it
    , dateTime = Messages.DateFormat.formatDateTime Language.Italian Time.utc
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
    , dateTime = Messages.DateFormat.formatDateTime Language.Spanish Time.utc
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
    , dateTime = Messages.DateFormat.formatDateTime Language.English Time.utc
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
    , dateTime = Messages.DateFormat.formatDateTime Language.German Time.utc
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
    , dateTime = Messages.DateFormat.formatDateTime Language.French Time.utc
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
    , dateTime = Messages.DateFormat.formatDateTime Language.Japanese Time.utc
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
    , dateTime = Messages.DateFormat.formatDateTime Language.Czech Time.utc
    }

br : Texts
br =
    { name = "Nome"
    , enabled = "Habilitado"
    , validity = "Validade"
    , created = "Criado"
    , edit = "Editar"
    , show = "Mostrar"
    , owner = "Proprietário"
    , validityField = Messages.ValidityField.br
    , dateTime = Messages.DateFormat.formatDateTime Language.Portuguese Time.utc
    }


applyZone : Time.Zone -> Language -> Texts -> Texts
applyZone zone lang texts =
    { texts | dateTime = Messages.DateFormat.formatDateTime lang zone }
