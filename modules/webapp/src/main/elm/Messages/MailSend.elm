module Messages.MailSend exposing
    ( Texts
    , de
    , gb
    , fr
    , ja
    , cz
    , es
    )

import Messages.MailForm


type alias Texts =
    { sendingEmail : String
    , loadingTemplate : String
    , mailForm : Messages.MailForm.Texts
    }


es : Texts
es =
    { sendingEmail = "Enviando correo ..."
    , loadingTemplate = "Cargando plantilla ..."
    , mailForm = Messages.MailForm.es
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

fr : Texts
fr =
    { sendingEmail = "Envoi de l'email ..."
    , loadingTemplate = "Chargement du modèle ..."
    , mailForm = Messages.MailForm.fr
    }


ja : Texts
ja =
    { sendingEmail = "メールを送信しています..."
    , loadingTemplate = "テンプレートを読み込んでいます..."
    , mailForm = Messages.MailForm.ja
    }

cz : Texts
cz =
    { sendingEmail = "Odeslat mail ..."
    , loadingTemplate = "Nahrát šablonu ..."
    , mailForm = Messages.MailForm.cz
    }
