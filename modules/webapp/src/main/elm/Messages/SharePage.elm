module Messages.SharePage exposing
    ( Texts
    , de
    , gb
    , fr
    )

import Messages.Dropzone2
import Messages.IntField
import Messages.MarkdownInput
import Messages.ValidityField


type alias Texts =
    { markdownInput : Messages.MarkdownInput.Texts
    , dropzone : Messages.Dropzone2.Texts
    , validityField : Messages.ValidityField.Texts
    , intField : Messages.IntField.Texts
    , sendFiles : String
    , description : String
    , sendMoreFiles : String
    , allFilesUploaded : String
    , someFilesFailedHeader : String
    , someFilesFailedText : String
    , someFilesFailedTextAddon : String
    , submit : String
    , clearFiles : String
    , resume : String
    , pause : String
    , password : String
    , createShare : String
    , details : String
    , name : String
    , namePlaceholder : String
    , validity : String
    , files : String
    , newShare : String
    , gotoShare : String
    , maxPublicViews : String
    , uploadsUpTo : String -> String
    }


gb : Texts
gb =
    { markdownInput = Messages.MarkdownInput.gb
    , dropzone = Messages.Dropzone2.gb
    , validityField = Messages.ValidityField.gb
    , intField = Messages.IntField.gb
    , sendFiles = "Send files"
    , description = "Description"
    , sendMoreFiles = "Send more files"
    , allFilesUploaded = "All files uploaded"
    , someFilesFailedHeader = "Some files failed"
    , someFilesFailedText = "Some files failed to upload…. You can try uploading them again. "
    , someFilesFailedTextAddon = "Go to the share and submit the same file again."
    , submit = "Submit"
    , clearFiles = "Clear Files"
    , resume = "Resume"
    , pause = "Pause"
    , password = "Password"
    , createShare = "Create a Share"
    , details = "Details"
    , name = "Name"
    , namePlaceholder = "Optional Name"
    , validity = "Validity"
    , files = "Files"
    , newShare = "New Share"
    , gotoShare = "Goto Share"
    , maxPublicViews = "Maximum Public Views"
    , uploadsUpTo =
        \size ->
            "Uploads are possible up to " ++ size ++ "."
    }


de : Texts
de =
    { markdownInput = Messages.MarkdownInput.de
    , dropzone = Messages.Dropzone2.de
    , validityField = Messages.ValidityField.de
    , intField = Messages.IntField.de
    , sendFiles = "Dateien versenden"
    , description = "Beschreibung"
    , sendMoreFiles = "Weitere Dateien versenden"
    , allFilesUploaded = "Alle Dateien hochgeladen"
    , someFilesFailedHeader = "Einige Dateien fehlerhaft"
    , someFilesFailedText =
        "Einigen Dateien konnten nicht hochgeladen werden. "
            ++ "Sie können versuchen, sie erneut hochzuladen. "
    , someFilesFailedTextAddon = "Gehen Sie zur Datei-Freigabe und laden Sie die gleiche Datei nochmal hoch."
    , submit = "Hochladen"
    , clearFiles = "Dateien entfernen"
    , resume = "Fortfahren"
    , pause = "Pause"
    , password = "Passwort"
    , createShare = "Neue Datei-Freigabe erstellen"
    , details = "Details"
    , name = "Name"
    , namePlaceholder = "Optionaler Name"
    , validity = "Gültigkeit"
    , files = "Dateien"
    , newShare = "Neue Freigabe"
    , gotoShare = "Zur Freigabe"
    , maxPublicViews = "Maximale Ansichten"
    , uploadsUpTo =
        \size ->
            "Es kann bis zu " ++ size ++ " hochgeladen werden."
    }

fr : Texts
fr =
    { markdownInput = Messages.MarkdownInput.fr
    , dropzone = Messages.Dropzone2.fr
    , validityField = Messages.ValidityField.fr
    , intField = Messages.IntField.fr
    , sendFiles = "Envoyer des fichiers"
    , description = "Description"
    , sendMoreFiles = "Envoyer plus de fichiers"
    , allFilesUploaded = "Tous les fichiers sont téléversés"
    , someFilesFailedHeader = "Certains téléversements ont échoué"
    , someFilesFailedText = "Certains téléversements ont échoué…. Vous pouvez essayer à nouveau. "
    , someFilesFailedTextAddon = "Retournez dans votre partage et envoyez le même fichier à nouveau."
    , submit = "Envoyer"
    , clearFiles = "Nettoyer les fichiers"
    , resume = "Reprendre"
    , pause = "Pause"
    , password = "Mot de passe"
    , createShare = "Créer un partage"
    , details = "Détails"
    , name = "Nom"
    , namePlaceholder = "Nom facultatif"
    , validity = "Validité"
    , files = "Fichiers"
    , newShare = "Nouveau partage"
    , gotoShare = "Voir le partage"
    , maxPublicViews = "Nombre maximum de vues"
    , uploadsUpTo =
        \size ->
            "Téléversements possibles jusqu'à " ++ size ++ "."
    }
