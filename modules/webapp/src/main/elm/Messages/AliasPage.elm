module Messages.AliasPage exposing
    ( Texts
    , de
    , fr
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
    , copyLink : String
    , owner : String
    , notOwnerInfo : String
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
    , copyLink = "Copy Link"
    , owner = "Owner"
    , notOwnerInfo = "This alias is owned by another user and shared with you. You cannot edit its properties."
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
    , copyLink = "Link kopieren"
    , owner = "Eigentümer"
    , notOwnerInfo = "Diese Alias-Seite gehört einen anderen Benutzer. Du kannst die Eigenschaften nicht bearbeiten."
    , aliasForm = Messages.AliasForm.de
    , aliasTable = Messages.AliasTable.de
    , mailSend = Messages.MailSend.de
    }


fr : Texts
fr =
    { createNew = "Créer une nouvelle page d'Alias"
    , aliasPage = "Page d'Alias: "
    , aliasPages = "Pages d'Alias"
    , newAliasPage = "Nouvelle page d'Alias"
    , searchPlaceholder = "Recherche…"
    , errorQrCode = "Erreur lors de l'encodage en QR Code."
    , shareThisLink = "Partager ce lien"
    , aliasPageNowAt = "La page d'alias est maintenant à: "
    , shareThisUrl = "Vous pouvez partager cette URL avec d'autres personnes pour recevoir des fichiers de leur part."
    , sendEmail = "Envoyer un email"
    , copyLink = "Copier le lien"
    , owner = "Owner"
    , notOwnerInfo = "This alias is owned by another user and shared with you. You cannot edit its properties."
    , aliasForm = Messages.AliasForm.fr
    , aliasTable = Messages.AliasTable.fr
    , mailSend = Messages.MailSend.fr
    }
