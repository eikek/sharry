module Messages.MailSend exposing
    ( Texts
    , de
    , gb
    )

import Messages.MailForm


type alias Texts =
    { sendingEmail : String
    , loadingTemplate : String
    , mailForm : Messages.MailForm.Texts
    }


gb : Texts
gb =
    { sendingEmail = "Sending mail ..."
    , loadingTemplate = "Loading template ..."
    , mailForm = Messages.MailForm.gb
    }


de : Texts
de =
    { sendingEmail = "Sende E-Mail ..."
    , loadingTemplate = "Lade Template ..."
    , mailForm = Messages.MailForm.de
    }
