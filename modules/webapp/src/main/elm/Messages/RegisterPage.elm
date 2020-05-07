module Messages.RegisterPage exposing
    ( Texts
    , de
    , gb
    , fr
    )

import Messages.FixedDropdown


type alias Texts =
    { signup : String
    , userLogin : String
    , password : String
    , passwordRepeat : String
    , invitationKey : String
    , submitButton : String
    , alreadySignedUp : String
    , signin : String
    , registrationSuccessful : String
    , dropdown : Messages.FixedDropdown.Texts
    }


gb : Texts
gb =
    { signup = "Sign up"
    , userLogin = "User Login"
    , password = "Password"
    , passwordRepeat = "Password (repeat)"
    , invitationKey = "Invitation Key"
    , submitButton = "Submit"
    , alreadySignedUp = "Already signed up?"
    , signin = "Sign in"
    , registrationSuccessful = "Registration successful."
    , dropdown = Messages.FixedDropdown.gb
    }


de : Texts
de =
    { signup = "Registrierung"
    , userLogin = "Benutzername"
    , password = "Passwort"
    , passwordRepeat = "Passwort (Wiederholung)"
    , invitationKey = "Einladungscode"
    , submitButton = "Absenden"
    , alreadySignedUp = "Schon registriert?"
    , signin = "Anmelden"
    , registrationSuccessful = "Registrierung erfolgreich."
    , dropdown = Messages.FixedDropdown.de
    }

fr : Texts
fr =
    { signup = "Inscription"
    , userLogin = "Identifiant"
    , password = "Mot de passe"
    , passwordRepeat = "Mot de passe (bis)"
    , invitationKey = "Clé d'invitation"
    , submitButton = "Envoyer"
    , alreadySignedUp = "Déjà inscrit ?"
    , signin = "Connexion"
    , registrationSuccessful = "Inscription réussie."
    , dropdown = Messages.FixedDropdown.fr
    }
