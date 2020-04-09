module Messages.MailForm exposing
    ( MailForm
    , gb
    )


type alias MailForm =
    { receivers : String
    , separateRecipientsByComma : String
    , subject : String
    , body : String
    , send : String
    , cancel : String
    }


gb : MailForm
gb =
    { receivers = "Receiver(s)"
    , separateRecipientsByComma = "Separate multiple recipients by comma"
    , subject = "Subject"
    , body = "Body"
    , send = "Send"
    , cancel = "Cancel"
    }
