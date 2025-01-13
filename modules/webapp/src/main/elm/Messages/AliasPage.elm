module Messages.AliasPage exposing
    ( Texts
    , de
    , fr
    , gb
    , ja
    , cz
    , es
	, it
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

it : Texts
it =
    { createNew = "Crea Nuova Pagina Alias"
    , aliasPage = "Pagina Alias: "
    , aliasPages = "Pagine Alias"
    , newAliasPage = "Nuova Pagina Alias"
    , searchPlaceholder = "Cerca…"
    , errorQrCode = "Errore durante la generazione del QRCode."
    , shareThisLink = "Condividi questo link"
    , aliasPageNowAt = "La pagina alias è: "
    , shareThisUrl = "Puoi condividere questo URL per ricevere files dagli altri."
    , sendEmail = "Invia E-Mail"
    , copyLink = "Copia Link"
    , owner = "Proprietario"
    , notOwnerInfo = "Il proprietario di questo alias è un altro utente e lo ha condiviso con te. Non puoi modificare le proprietà."
    , aliasForm = Messages.AliasForm.it
    , aliasTable = Messages.AliasTable.it
    , mailSend = Messages.MailSend.it
    }

es : Texts
es =
    { createNew = "Crear Nueva Página de Alias"
    , aliasPage = "Página de Alias: "
    , aliasPages = "Páginas de Alias"
    , newAliasPage = "Nueva Página de Alias"
    , searchPlaceholder = "Buscar…"
    , errorQrCode = "Error al codificar en QRCode."
    , shareThisLink = "Compartir este enlace"
    , aliasPageNowAt = "La página de alias está ahora en: "
    , shareThisUrl = "Puedes compartir esta URL con otros para recibir archivos de ellos."
    , sendEmail = "Enviar E-Mail"
    , copyLink = "Copiar Enlace"
    , owner = "Propietario"
    , notOwnerInfo = "Este alias pertenece a otro usuario y ha sido compartido contigo. No puedes editar sus propiedades."
    , aliasForm = Messages.AliasForm.es
    , aliasTable = Messages.AliasTable.es
    , mailSend = Messages.MailSend.es
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


ja : Texts
ja =
    { createNew = "受信箱の新規作成"
    , aliasPage = "受信箱 : "
    , aliasPages = "あなたの受信箱"
    , newAliasPage = "受信箱の新規作成"
    , searchPlaceholder = "検索..."
    , errorQrCode = "QR コードの生成でエラーが発生しました。"
    , shareThisLink = "このリンクを共有"
    , aliasPageNowAt = "この受信箱への URL : "
    , shareThisUrl = "この URL を共有することで、相手からファイルを受信できます。"
    , sendEmail = "メール送信"
    , copyLink = "リンクをコピー"
    , owner = "所有者"
    , notOwnerInfo = "この受信箱はほかのユーザーが所有していますが、あなたと共同作業しています。情報の変更は所有者でなければできません。"
    , aliasForm = Messages.AliasForm.ja
    , aliasTable = Messages.AliasTable.ja
    , mailSend = Messages.MailSend.ja
    }

cz : Texts
cz =
    { createNew = "Vytvořit prostor pro sdílení"
    , aliasPage = "Prostor pro sdílení: "
    , aliasPages = "Prostory pro sdílení"
    , newAliasPage = "Nový prostor pro sdílení"
    , searchPlaceholder = "Vyhledat…"
    , errorQrCode = "Chyba při načítání QR kódu."
    , shareThisLink = "Sdílet tento odkaz"
    , aliasPageNowAt = "Tento prostor pro sdílení je nyní dostupný na webové adrese: "
    , shareThisUrl = "Tuto URL nebo QR kód níže můžete sdílet s ostatními."
    , sendEmail = "Odeslat E-Mail"
    , copyLink = " Kopírovat odkaz"
    , owner = "Vlastník"
    , notOwnerInfo = "Tento prostor je sdílen jiným uživatelem a sdílený Vámi. Nemůžete měnit jeho vlastnosti."
    , aliasForm = Messages.AliasForm.cz
    , aliasTable = Messages.AliasTable.cz
    , mailSend = Messages.MailSend.cz
    }

