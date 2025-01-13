module Messages.SharePage exposing
    ( Texts
    , de
    , gb
    , fr
    , ja
    , cz
    , es
    , it
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

it : Texts
it =
    { markdownInput = Messages.MarkdownInput.it
    , dropzone = Messages.Dropzone2.it
    , validityField = Messages.ValidityField.it
    , intField = Messages.IntField.it
    , sendFiles = "Invia files"
    , description = "Descrizione"
    , sendMoreFiles = "Invia altri files"
    , allFilesUploaded = "Tutti i files caricati"
    , someFilesFailedHeader = "Alcuni files hanno fallito"
    , someFilesFailedText = "Alcuni files hanno fallito durante il caricamento…. Puoi riprovare l'invio. "
    , someFilesFailedTextAddon = "Vai alla condivisione ed invia gli stessi files di nuovo."
    , submit = "Invia"
    , clearFiles = "Pulisci Files"
    , resume = "Riprendi"
    , pause = "Pausa"
    , password = "Password"
    , createShare = "Crea Condivisione"
    , details = "Dettagli"
    , name = "Nome"
    , namePlaceholder = "Nome Opzionale"
    , validity = "Validità"
    , files = "Files"
    , newShare = "Nuova Condivisione"
    , gotoShare = "Vai alla Condivisione"
    , maxPublicViews = "Limite Visualizzazioni Pubbliche"
    , uploadsUpTo =
        \size ->
            "Si possono caricare files fino a " ++ size ++ "."
    }


es : Texts
es =
    { markdownInput = Messages.MarkdownInput.es
    , dropzone = Messages.Dropzone2.es
    , validityField = Messages.ValidityField.es
    , intField = Messages.IntField.es
    , sendFiles = "Enviar archivos"
    , description = "Descripción"
    , sendMoreFiles = "Enviar más archivos"
    , allFilesUploaded = "Todos los archivos subidos"
    , someFilesFailedHeader = "Algunos archivos fallaron"
    , someFilesFailedText = "Algunos archivos no se pudieron subir…. Puedes intentar subirlos de nuevo. "
    , someFilesFailedTextAddon = "Ve al compartido y envía el mismo archivo nuevamente."
    , submit = "Enviar"
    , clearFiles = "Limpiar Archivos"
    , resume = "Reanudar"
    , pause = "Pausar"
    , password = "Contraseña"
    , createShare = "Crear un Compartido"
    , details = "Detalles"
    , name = "Nombre"
    , namePlaceholder = "Nombre Opcional"
    , validity = "Validez"
    , files = "Archivos"
    , newShare = "Nuevo Compartido"
    , gotoShare = "Ir al Compartido"
    , maxPublicViews = "Vistas Públicas Máximas"
    , uploadsUpTo =
        \size ->
            "Las subidas son posibles hasta " ++ size ++ "."
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


ja : Texts
ja =
    { markdownInput = Messages.MarkdownInput.ja
    , dropzone = Messages.Dropzone2.ja
    , validityField = Messages.ValidityField.ja
    , intField = Messages.IntField.ja
    , sendFiles = "ファイルアップロード"
    , description = "説明"
    , sendMoreFiles = "さらにファイルを追加"
    , allFilesUploaded = "すべてのファイルをアップロードしました"
    , someFilesFailedHeader = "いくつかのファイルで失敗"
    , someFilesFailedText = "いくつかのファイルのアップロードに失敗しました。再度アップロードすることもできます。"
    , someFilesFailedTextAddon = "共有画面に戻って、同じファイルを再度アップロードしてください。"
    , submit = "保存"
    , clearFiles = "ファイルをクリアー"
    , resume = "再開"
    , pause = "一時停止"
    , password = "パスワード"
    , createShare = "共有の作成"
    , details = "詳細"
    , name = "共有名"
    , namePlaceholder = "共有の名前 (任意)"
    , validity = "共有期限"
    , files = "ファイル"
    , newShare = "共有の新規作成"
    , gotoShare = "共有へ"
    , maxPublicViews = "最大表示回数"
    , uploadsUpTo =
        \size ->
            "アップロードは最大 " ++ size ++ " までです。"
    }

cz : Texts
cz =
    { markdownInput = Messages.MarkdownInput.cz
    , dropzone = Messages.Dropzone2.cz
    , validityField = Messages.ValidityField.cz
    , intField = Messages.IntField.cz
    , sendFiles = "Odeslat soubory"
    , description = "Popis"
    , sendMoreFiles = "Odeslat další soubory"
    , allFilesUploaded = "Všechny soubory byly úspěšně nahrány"
    , someFilesFailedHeader = "Nahrání některých souborů se nezdařilo"
    , someFilesFailedText = "Nahrání některých souborů se nezdařilo…. Nahrajte soubory znovu. "
    , someFilesFailedTextAddon = "Přejděte do sdílení souborů a akci opakujte."
    , submit = "Odeslat"
    , clearFiles = "Smazat formulář"
    , resume = "Pokračovat"
    , pause = "Pozastavit"
    , password = "Heslo"
    , createShare = "Vytvořit nové sdílení"
    , details = "Detaily"
    , name = "Název"
    , namePlaceholder = "Volitelný název"
    , validity = "Platnost"
    , files = "Soubory"
    , newShare = "Nové sdílení"
    , gotoShare = "Přejít na právě vytvořené sdílení"
    , maxPublicViews = "Maximální počet zobrazení"
    , uploadsUpTo =
        \size ->
            "Velikost souborů je maximálně " ++ size ++ "."
    }
