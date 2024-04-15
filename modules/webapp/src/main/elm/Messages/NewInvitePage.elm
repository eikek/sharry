module Messages.NewInvitePage exposing
    ( Texts
    , de
    , gb
    , fr
    , ja
    , cz
    )

import Html exposing (Html, p, text)


type alias Texts =
    { createNewTitle : String
    , newInvitePassword : String
    , submit : String
    , reset : String
    , error : String
    , success : String
    , invitationKey : String
    , message : List (Html Never)
    }


gb : Texts
gb =
    { createNewTitle = "Create new invitations"
    , newInvitePassword = "New Invitation Password"
    , submit = "Submit"
    , reset = "Reset"
    , error = "Error"
    , success = "Success"
    , invitationKey = "Invitation Key:"
    , message =
        [ p []
            [ text
                """Sharry requires an invite when signing up. You can
             create these invites here and send them to friends so
             they can signup with Sharry."""
            ]
        , p []
            [ text
                """Each invite can only be used once. You'll need to
             create one key for each person you want to invite."""
            ]
        , p []
            [ text
                """Creating an invite requires providing the password
             from the configuration."""
            ]
        ]
    }


de : Texts
de =
    { createNewTitle = "Neue Einladungen erstellen"
    , newInvitePassword = "Password zum Erstellen neuer Einladungen"
    , submit = "Code erzeugen"
    , reset = "Zurücksetzen"
    , error = "Fehler"
    , success = "Erfolg"
    , invitationKey = "Einladungs-Code:"
    , message =
        [ p []
            [ text
                """Sharry erfordert einen Code zum Registrieren. Sie können
             diese Codes hier erzeugen und ihn Freunden zukommen lassen, die
             sich dann hier registrieren können."""
            ]
        , p []
            [ text
                """Jeder Code kann genau einmal verwendet werden. Sie müssen
              für jede Person einen separaten Code erzeugen."""
            ]
        , p []
            [ text
                """Um einen Einladungs-Code zu erzeugen, ist ein Passwort aus
                 der Konfiguration erforderlich."""
            ]
        ]
    }

fr : Texts
fr =
    { createNewTitle = "Créer des invitations"
    , newInvitePassword = "Mot de passe d'invitation"
    , submit = "Envoyer"
    , reset = "Réinitialiser"
    , error = "Erreur"
    , success = "Succès"
    , invitationKey = "Clé d'invitation:"
    , message =
        [ p []
            [ text
                """Sharry exige une invitation lors de l'inscription. 
             Vous pouvez créer ces invitations ici et les envoyer à 
             vos amis afin qu'ils puissent s'inscrire."""
            ]
        , p []
            [ text
                """Chaque invitation ne peut être utilisée qu'une seule fois.
             Vous devrez créer une clé pour chaque personne que vous souhaitez inviter."""
            ]
        , p []
            [ text
                """Pour créer une invitation, il faut fournir le mot de passe choisi lors de la configuration."""
            ]
        ]
    }


ja : Texts
ja =
    { createNewTitle = "招待キーの新規作成"
    , newInvitePassword = "キー"
    , submit = "保存"
    , reset = "リセット"
    , error = "エラー"
    , success = "成功"
    , invitationKey = "招待パスワード : "
    , message =
        [ p []
            [ text
                """このシステムは、招待を受けた方だけがユーザー登録可能です。
                ここで招待キーを作成することができます。
                必要な方に招待キーを知らせることで、その方はユーザー登録を進めることができます。"""
            ]
        , p []
            [ text
                """招待キーは 1 回 ( 1 人のユーザー登録 ) のみ有効です。
                招待したい方 1 人ずつに招待コードを作る必要があります。"""
            ]
        , p []
            [ text
                """招待キーの作成には、設定された「招待パスワード」が必要です。"""
            ]
        ]
    }



cz : Texts
cz =
    { createNewTitle = "Vytvořit novou pozvánku"
    , newInvitePassword = "Heslo k nové pozvánce"
    , submit = "Odeslat"
    , reset = "Reset"
    , error = "Chyba"
    , success = "Pozvánka úspěšně vygenerována"
    , invitationKey = "Klíč k pozvánce:"
    , message =
        [ p []
            [ text
                """Sharry vyžaduje při registraci pozvánku. Tyto 
             pozvánky můžete vytvářet zde a následně je zaslat uživatelům,
              aby se mohli zaregistrovat v Sharry."""
            ]
        , p []
            [ text
                """Každou pozvánku lze použít pouze jednou. Musíte
             vytvořit jeden klíč pro každou osobu, kterou chcete pozvat."""
            ]
        , p []
            [ text
                """Vytvoření pozvánky vyžaduje zadání hesla
             z konfigurace."""
            ]
        ]
    }
