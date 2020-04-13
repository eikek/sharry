module Messages.AliasPage exposing
    ( Texts
    , de
    , gb
    )

import Messages.AliasForm
import Messages.AliasTable
import Messages.MailSend


type alias Texts =
    { createNew : String
    , aliasPage : String
    , aliasPages : String
    , newAliasPage : String
    , searchPlaceholder : String
    , errorQrCode : String
    , shareThisLink : String
    , aliasPageNowAt : String
    , shareThisUrl : String
    , sendEmail : String
    , aliasForm : Messages.AliasForm.Texts
    , aliasTable : Messages.AliasTable.Texts
    , mailSend : Messages.MailSend.Texts
    }


gb : Texts
gb =
    { createNew = "Create New Alias Page"
    , aliasPage = "Alias Page: "
    , aliasPages = "Alias Pages"
    , newAliasPage = "New Alias Page"
    , searchPlaceholder = "Search…"
    , errorQrCode = "Error while encoding to QRCode."
    , shareThisLink = "Share this link"
    , aliasPageNowAt = "The alias page is now at: "
    , shareThisUrl = "You can share this URL with others to receive files from them."
    , sendEmail = "Send E-Mail"
    , aliasForm = Messages.AliasForm.gb
    , aliasTable = Messages.AliasTable.gb
    , mailSend = Messages.MailSend.gb
    }


de : Texts
de =
    { createNew = "Neue Alias Seite erstellen"
    , aliasPage = "Alias Seite: "
    , aliasPages = "Alias Seiten"
    , newAliasPage = "Neue Alias Seite"
    , searchPlaceholder = "Suche…"
    , errorQrCode = "Fehler beim Erstellen des QR-Code."
    , shareThisLink = "Teile diesen Link"
    , aliasPageNowAt = "Die Alias Seite ist nun hier: "
    , shareThisUrl = "Du kannst diese URL mit anderen teilen, um von ihnen Dateien zu erhalten."
    , sendEmail = "Sende E-Mail"
    , aliasForm = Messages.AliasForm.de
    , aliasTable = Messages.AliasTable.de
    , mailSend = Messages.MailSend.de
    }
