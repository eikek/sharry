module Messages.DetailPage exposing
    ( Texts
    , de
    , gb
    )

import Messages.Dropzone2
import Messages.MailSend
import Messages.MarkdownInput
import Messages.ShareFileList
import Messages.ValidityField
import Messages.YesNoDimmer


type alias Texts =
    { mailSend : Messages.MailSend.Texts
    , save : String
    , yourShare : String
    , markdownInput : Messages.MarkdownInput.Texts
    , shareFileList : Messages.ShareFileList.Texts
    , yesNo : Messages.YesNoDimmer.Texts
    , sharePublished : String
    , shareNotPublished : String
    , shareLinkExpired : String
    , errorQrCode : String
    , sharePublicAvailableAt : String
    , shareAsYouLike : String
    , sendEmail : String
    , name : String
    , validity : String
    , maxViews : String
    , password : String
    , passwordProtected : String
    , passwordNone : String
    , shareSize : String
    , created : String
    , aliasLabel : String
    , publishedOn : String
    , publishedUntil : String
    , lastAccess : String
    , views : String
    , publishWithNewLink : String
    , delete : String
    , edit : String
    , detailsMenu : String
    , shareLinkMenu : String
    , editDescription : String
    , publish : String
    , unpublish : String
    , listView : String
    , cardView : String
    , submit : String
    , clear : String
    , resume : String
    , pause : String
    , uploadsGreaterThan : String -> String
    , waitDeleteShare : String
    , loadingData : String
    , dropzone : Messages.Dropzone2.Texts
    , validityField : Messages.ValidityField.Texts
    , passwordRequired : String
    , passwordInvalid : String
    , or : String
    }


gb : Texts
gb =
    { mailSend = Messages.MailSend.gb
    , save = "Save"
    , yourShare = "Your Share"
    , markdownInput = Messages.MarkdownInput.gb
    , shareFileList = Messages.ShareFileList.gb
    , yesNo = Messages.YesNoDimmer.gb
    , sharePublished =
        "The share has been published, but its max-views has been reached. You can "
            ++ "increase this property if you want to have this published for another while."
    , shareNotPublished =
        "In order to share this with others, you need to publish "
            ++ "this share. Then everyone you'll send the generated link "
            ++ "can access this data."
    , shareLinkExpired =
        "The share has been published, but it is now expired. You can "
            ++ "first unpublish and then publish it again."
    , errorQrCode = "Error while encoding to QRCode."
    , sharePublicAvailableAt = "The share is publicly available at"
    , shareAsYouLike = "You can share this link to all you'd like to access this data."
    , sendEmail = "Send E-Mail"
    , name = "Name"
    , validity = "Validity Time"
    , maxViews = "Max. Views"
    , password = "Password"
    , passwordProtected = "Password Protected"
    , passwordNone = "None"
    , shareSize = "#/Size"
    , created = "Created"
    , aliasLabel = "Alias"
    , publishedOn = "Published on"
    , publishedUntil = "Published until"
    , lastAccess = "Last Access"
    , views = "Views"
    , publishWithNewLink = "Publish with new Link"
    , delete = "Delete"
    , edit = "Edit"
    , detailsMenu = "Details"
    , shareLinkMenu = "Share Link"
    , editDescription = "Edit description"
    , publish = "Publish"
    , unpublish = "Unpublish"
    , listView = "List View"
    , cardView = "Card View"
    , submit = "Submit"
    , clear = "Clear"
    , resume = "Resume"
    , pause = "Pause"
    , uploadsGreaterThan =
        \size ->
            "All uploads must not be greater than " ++ size ++ "."
    , waitDeleteShare = "Deleting share. Please wait."
    , loadingData = "Loading data..."
    , dropzone = Messages.Dropzone2.gb
    , validityField = Messages.ValidityField.gb
    , passwordRequired = "Password required"
    , passwordInvalid = "Password invalid"
    , or = "Or"
    }


de : Texts
de =
    { mailSend = Messages.MailSend.de
    , save = "Speichern"
    , yourShare = "Deine Datei-Freigabe"
    , markdownInput = Messages.MarkdownInput.de
    , shareFileList = Messages.ShareFileList.de
    , yesNo = Messages.YesNoDimmer.de
    , sharePublished =
        "Die Dateien sind veröffentlicht, aber das Limit für die maximale Ansicht wurde erreicht."
            ++ " Sie können das Limit erhöhen, um die Veröffentlichung zu verlängern."
    , shareNotPublished =
        "Sie müssen diese Datei-Freigabe veröffentlichen, damit andere Zugriff erhalten können. "
            ++ "Den damit erzeugten Link können Sie mit anderen teilen, die damit dann die "
            ++ "Dateien einsehen können."
    , shareLinkExpired =
        "Die Datei-Freigabe wurde veröffentlicht, aber die Gültigkeit ist abgelaufen. Sie können "
            ++ "sie erneut veröffentlichen, indem sie zuerts „Veröffentlichung zurückziehen” klicken "
            ++ "und danach wieder „Veröffentlichen”."
    , errorQrCode = "Fehler beim Erzeugen des QR-Codes."
    , sharePublicAvailableAt = "Die Datei-Freigabe ist hier öffentlich verfügbar:"
    , shareAsYouLike = "Sie können diesen Link mit denen teilen, die Zugriff auf diese Dateien bekommen sollen."
    , sendEmail = "Sende E-Mail"
    , name = "Name"
    , validity = "Gültigkeit"
    , maxViews = "Max. Ansichten"
    , password = "Passwort"
    , passwordProtected = "Passwortgeschützt"
    , passwordNone = "Keins"
    , shareSize = "#/Größe"
    , created = "Erstellt"
    , aliasLabel = "Alias"
    , publishedOn = "Veröffentlicht am"
    , publishedUntil = "Veröffentlicht bis"
    , lastAccess = "Letzter Zugriff"
    , views = "Ansichten"
    , publishWithNewLink = "Neuen Link veröffentlichen"
    , delete = "Löschen"
    , edit = "Ändern"
    , detailsMenu = "Details"
    , shareLinkMenu = "Link teilen"
    , editDescription = "Beschreibung ändern"
    , publish = "Veröffentlichen"
    , unpublish = "Veröffentlichung zurückziehen"
    , listView = "Listen Ansicht"
    , cardView = "Kachel Ansicht"
    , submit = "Absenden"
    , clear = "Zurücksetzen"
    , resume = "Fortfahren"
    , pause = "Pause"
    , uploadsGreaterThan =
        \size ->
            "Alle Dateien dürfen nicht größer sein als " ++ size ++ "."
    , waitDeleteShare = "Datei-Freigabe wird gelöscht. Bitte warten."
    , loadingData = "Lade Daten ..."
    , dropzone = Messages.Dropzone2.de
    , validityField = Messages.ValidityField.de
    , passwordRequired = "Passwort erforderlich"
    , passwordInvalid = "Passwort ungültig"
    , or = "Oder"
    }
