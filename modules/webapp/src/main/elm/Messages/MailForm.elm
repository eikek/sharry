module Messages.MailForm exposing
    ( Texts
    , gb
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
