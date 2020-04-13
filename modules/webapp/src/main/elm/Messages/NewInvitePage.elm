module Messages.NewInvitePage exposing
    ( Texts
    , de
    , gb
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
