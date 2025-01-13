module Messages.YesNoDimmer exposing
    ( Texts
    , de
    , gb
    , fr
    , ja
    , cz
    , es
	, it
    )


type alias Texts =
    { message : String
    , confirmButton : String
    , cancelButton : String
    }

it : Texts
it =
    { message = "Eliminare questo elemento permanentemente?"
    , confirmButton = "Si, fallo!"
    , cancelButton = "No"
    }

es : Texts
es =
    { message = "¿Eliminar este elemento de forma permanente?"
    , confirmButton = "¡Sí, hazlo!"
    , cancelButton = "No"
    }


gb : Texts
gb =
    { message = "Delete this item permanently?"
    , confirmButton = "Yes, do it!"
    , cancelButton = "No"
    }


de : Texts
de =
    { message = "Dauerhaft entfernen?"
    , confirmButton = "Ja, bitte!"
    , cancelButton = "Nein"
    }

fr : Texts
fr =
    { message = "Supprimer définitivement ?"
    , confirmButton = "Oui, Allons-y !"
    , cancelButton = "Non"
    }

ja : Texts
ja =
    { message = "このアイテムを完全に削除します。よろしいですか ?"
    , confirmButton = "はい、削除してください。"
    , cancelButton = "いいえ"
    }

cz : Texts
cz =
    { message = "Smazat trvale tuto položku?"
    , confirmButton = "Ano, prosím!"
    , cancelButton = "Ne"
    }
