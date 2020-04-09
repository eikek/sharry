module Messages.MailSend exposing
    ( MailSend
    , gb
    )

import Messages.MailForm exposing (MailForm)


type alias MailSend =
    { sendingEmail : String
    , loadingTemplate : String
    , mailForm : MailForm
    }


gb : MailSend
gb =
    { sendingEmail = "Sending mail ..."
    , loadingTemplate = "Loading template ..."
    , mailForm = Messages.MailForm.gb
    }
