module Messages.MailForm exposing
    ( Texts
    , de
    , gb
    , fr
    )


type alias Texts =
    { receivers : String
    , separateRecipientsByComma : String
    , subject : String
    , body : String
    , send : String
    , cancel : String
    }


gb : Texts
gb =
    { receivers = "Receiver(s)"
    , separateRecipientsByComma = "Separate multiple recipients by comma"
    , subject = "Subject"
    , body = "Body"
    , send = "Send"
    , cancel = "Cancel"
    }


de : Texts
de =
    { receivers = "Empfänger"
    , separateRecipientsByComma = "Mehrere Empfänger durch Komma trennen"
    , subject = "Betreff"
    , body = "E-Mail Text"
    , send = "Absenden"
    , cancel = "Abbrechen"
    }

fr : Texts
fr =
    { receivers = "Destinataire(s)"
    , separateRecipientsByComma = "Séparez de multiples destinataires par une virgule"
    , subject = "Sujet"
    , body = "Corps"
    , send = "Envoi"
    , cancel = "Annulation"
    }
