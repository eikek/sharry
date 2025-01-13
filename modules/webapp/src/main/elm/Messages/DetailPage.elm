module Messages.DetailPage exposing
    ( Texts
    , de
    , fr
    , gb
    , ja
    , cz
    , es
    , it
    )

import Data.InitialView exposing (InitialView)
import Language
import Messages.DateFormat
import Messages.Dropzone2
import Messages.MailSend
import Messages.MarkdownInput
import Messages.ShareFileList
import Messages.ValidityField
import Messages.YesNoDimmer


type alias Texts =
    { mailSend : Messages.MailSend.Texts
    , save : String
    , cancel : String
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
    , copyLink : String
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
    , addFilesLinkMenu : String
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
    , dateTime : Int -> String
    , initialViewLabel : InitialView -> String
    , initialViewField : String
    }

it : Texts
it =
    { mailSend = Messages.MailSend.it
    , save = "Salva"
    , cancel = "Annulla"
    , yourShare = "Le mie condivisioni"
    , markdownInput = Messages.MarkdownInput.it
    , shareFileList = Messages.ShareFileList.it
    , yesNo = Messages.YesNoDimmer.it
    , sharePublished =
        "La condivisione è stata pubblicata, ma il numero massimo di visualizzazione è stato raggiunto. Puoi "
            ++ "incrementare questa proprietà se vuoi continuare la pubblicazione."
    , shareNotPublished =
        "Per condividere con gli altri, devi pubblicare "
            ++ "questa condivisione. In questo modo tutti quelli a cui invierai il link generato "
            ++ "potranno accedere a questi dati."
    , shareLinkExpired =
        "La condivisione è stata pubblicata, risulta scaduta. Puoi "
            ++ "ripubblicare la condivisione."
    , errorQrCode = "Errore durante la codifica del QRCode."
    , sharePublicAvailableAt = "La condivisione è accessibile pubblicamente a"
    , shareAsYouLike = "Puoi condividere questo link con chi vuoi per farli accedere ai dati."
    , sendEmail = "Invia E-Mail"
    , copyLink = "Copia Link"
    , name = "Nome"
    , validity = "Tempo Validità"
    , maxViews = "Max. Visualizzazioni"
    , password = "Password"
    , passwordProtected = "Protetto da Password"
    , passwordNone = "Nessuna"
    , shareSize = "#/Dimensione"
    , created = "Creazione"
    , aliasLabel = "Alias"
    , publishedOn = "Pubblicato su"
    , publishedUntil = "Pubblicato fino a"
    , lastAccess = "Ultimo Accesso"
    , views = "Visualizzazioni"
    , publishWithNewLink = "Pubblica con nuovo Link"
    , delete = "Elimina"
    , edit = "Modifica"
    , detailsMenu = "Dettagli"
    , shareLinkMenu = "Condividi Link"
    , addFilesLinkMenu = "Aggiungi files"
    , editDescription = "Modifica descrizione"
    , publish = "Pubblica"
    , unpublish = "Annulla Pubblicazione"
    , listView = "Vista a Lista"
    , cardView = "Vista a Carte"
    , submit = "Invia"
    , clear = "Pulisci"
    , resume = "Riprendi"
    , pause = "Pausa"
    , uploadsGreaterThan =
        \size ->
            "Tutti i caricamenti non devono superare i " ++ size ++ "."
    , waitDeleteShare = "Eliminazione condivisione. Attendi."
    , loadingData = "Caricamento dati..."
    , dropzone = Messages.Dropzone2.it
    , validityField = Messages.ValidityField.it
    , passwordRequired = "Password necessaria"
    , passwordInvalid = "Password non valida"
    , or = "Oppure"
    , dateTime = Messages.DateFormat.formatDateTime Language.Italian
    , initialViewLabel =
        \iv ->
            case iv of
                Data.InitialView.Listing ->
                    "Lista"

                Data.InitialView.Cards ->
                    "Carte"

                Data.InitialView.Zoom ->
                    "Anteprima"
    , initialViewField = "Vista iniziale"
    }

es : Texts
es =
    { mailSend = Messages.MailSend.es
    , save = "Guardar"
    , cancel = "Cancelar"
    , yourShare = "Tu Compartido"
    , markdownInput = Messages.MarkdownInput.es
    , shareFileList = Messages.ShareFileList.es
    , yesNo = Messages.YesNoDimmer.es
    , sharePublished =
        "El compartido ha sido publicado, pero se ha alcanzado el límite de vistas. Puedes "
            ++ "aumentar esta propiedad si deseas que siga publicado por más tiempo."
    , shareNotPublished =
        "Para compartir esto con otros, necesitas publicar "
            ++ "este compartido. Luego, todos a quienes les envíes el enlace generado "
            ++ "podrán acceder a estos datos."
    , shareLinkExpired =
        "El compartido ha sido publicado, pero ahora está expirado. Puedes "
            ++ "despublicarlo y luego publicarlo nuevamente."
    , errorQrCode = "Error al codificar en QRCode."
    , sharePublicAvailableAt = "El compartido está disponible públicamente en"
    , shareAsYouLike = "Puedes compartir este enlace con todos los que desees que accedan a estos datos."
    , sendEmail = "Enviar E-Mail"
    , copyLink = "Copiar Enlace"
    , name = "Nombre"
    , validity = "Tiempo de Validez"
    , maxViews = "Máx. Vistas"
    , password = "Contraseña"
    , passwordProtected = "Protegido con Contraseña"
    , passwordNone = "Ninguna"
    , shareSize = "#/Tamaño"
    , created = "Creado"
    , aliasLabel = "Alias"
    , publishedOn = "Publicado el"
    , publishedUntil = "Publicado hasta"
    , lastAccess = "Último Acceso"
    , views = "Vistas"
    , publishWithNewLink = "Publicar con nuevo Enlace"
    , delete = "Eliminar"
    , edit = "Editar"
    , detailsMenu = "Detalles"
    , shareLinkMenu = "Enlace Compartido"
    , addFilesLinkMenu = "Agregar archivos"
    , editDescription = "Editar descripción"
    , publish = "Publicar"
    , unpublish = "Despublicar"
    , listView = "Vista de Lista"
    , cardView = "Vista de Tarjeta"
    , submit = "Enviar"
    , clear = "Limpiar"
    , resume = "Reanudar"
    , pause = "Pausar"
    , uploadsGreaterThan =
        \size ->
            "Todas las subidas no deben ser mayores que " ++ size ++ "."
    , waitDeleteShare = "Eliminando compartido. Por favor espera."
    , loadingData = "Cargando datos..."
    , dropzone = Messages.Dropzone2.es
    , validityField = Messages.ValidityField.es
    , passwordRequired = "Contraseña requerida"
    , passwordInvalid = "Contraseña inválida"
    , or = "O"
    , dateTime = Messages.DateFormat.formatDateTime Language.Spanish
    , initialViewLabel =
        \iv ->
            case iv of
                Data.InitialView.Listing ->
                    "Listado"

                Data.InitialView.Cards ->
                    "Tarjetas"

                Data.InitialView.Zoom ->
                    "Vista Previa"
    , initialViewField = "Vista inicial"
    }


gb : Texts
gb =
    { mailSend = Messages.MailSend.gb
    , save = "Save"
    , cancel = "Cancel"
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
    , copyLink = "Copy Link"
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
    , addFilesLinkMenu = "Add files"
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
    , dateTime = Messages.DateFormat.formatDateTime Language.English
    , initialViewLabel =
        \iv ->
            case iv of
                Data.InitialView.Listing ->
                    "Listing"

                Data.InitialView.Cards ->
                    "Cards"

                Data.InitialView.Zoom ->
                    "Preview"
    , initialViewField = "Initial view"
    }


de : Texts
de =
    { mailSend = Messages.MailSend.de
    , save = "Speichern"
    , cancel = "Abbrechen"
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
    , copyLink = "Link kopieren"
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
    , addFilesLinkMenu = "Dateien hinzufügen"
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
    , dateTime = Messages.DateFormat.formatDateTime Language.German
    , initialViewLabel =
        \iv ->
            case iv of
                Data.InitialView.Listing ->
                    "Liste"

                Data.InitialView.Cards ->
                    "Kacheln"

                Data.InitialView.Zoom ->
                    "Vorschau"
    , initialViewField = "Anfangsansicht"
    }



-- TODO check French translations


fr : Texts
fr =
    { mailSend = Messages.MailSend.fr
    , save = "Sauver"
    , cancel = "Annulation"
    , yourShare = "Votre partage"
    , markdownInput = Messages.MarkdownInput.fr
    , shareFileList = Messages.ShareFileList.fr
    , yesNo = Messages.YesNoDimmer.fr
    , sharePublished =
        "Le partage a été publié mais le nombre de vues maximal a été atteint. Vous pouvez "
            ++ "augmenter cette propriété si vous souhaitez le publier pendant un certain temps encore."
    , shareNotPublished =
        "Afin de partager ceci avec d'autres, vous devez publier "
            ++ "ce partage. Ensuite, envoyez le lien généré à chaque "
            ++ "personne pour qu’elle y accède."
    , shareLinkExpired =
        "Le partage est publié mais il a expiré. Vous pouvez  "
            ++ "premièrement le dépublier pour le publier à nouveau."
    , errorQrCode = "Erreur lors de l'encodage en QR Code."
    , sharePublicAvailableAt = "Ce partage est accessible au public à l'adresse suivante"
    , shareAsYouLike = "Vous pouvez partager ce lien avec tous ceux qui souhaitent accéder à ces données."
    , sendEmail = "Envoyer un email"
    , copyLink = "Copier le lien"
    , name = "Nom"
    , validity = "Durée de validité"
    , maxViews = "Vues max."
    , password = "Mot de passe"
    , passwordProtected = "Protégé"
    , passwordNone = "Sans"
    , shareSize = "#/Taille"
    , created = "Créé le"
    , aliasLabel = "Alias"
    , publishedOn = "Publié le"
    , publishedUntil = "Expiration"
    , lastAccess = "Dernier accès"
    , views = "Vues"
    , publishWithNewLink = "Publier avec un nouveau lien"
    , delete = "Supprimer"
    , edit = "Éditer"
    , detailsMenu = "Détails"
    , shareLinkMenu = "Lien de partage"
    , addFilesLinkMenu = "Ajouter des fichiers"
    , editDescription = "Modifier la description"
    , publish = "Publier"
    , unpublish = "Dépublier"
    , listView = "Liste"
    , cardView = "Miniatures"
    , submit = "Envoyer"
    , clear = "Nettoyer"
    , resume = "Reprendre"
    , pause = "Pause"
    , uploadsGreaterThan =
        \size ->
            "Chaque téléversement ne doit pas dépasser " ++ size ++ "."
    , waitDeleteShare = "Suppresion du partage. Patientez."
    , loadingData = "Chargement..."
    , dropzone = Messages.Dropzone2.fr
    , validityField = Messages.ValidityField.fr
    , passwordRequired = "Mot de passe requis"
    , passwordInvalid = "Mot de passe invalide"
    , or = "Ou"
    , dateTime = Messages.DateFormat.formatDateTime Language.French
    , initialViewLabel =
        \iv ->
            case iv of
                Data.InitialView.Listing ->
                    "Listing"

                Data.InitialView.Cards ->
                    "Cards"

                Data.InitialView.Zoom ->
                    "Preview"
    , initialViewField = "Initial view"
    }

ja : Texts
ja =
    { mailSend = Messages.MailSend.ja
    , save = "保存"
    , cancel = "キャンセル"
    , yourShare = "共有 (名前なし)"
    , markdownInput = Messages.MarkdownInput.ja
    , shareFileList = Messages.ShareFileList.ja
    , yesNo = Messages.YesNoDimmer.ja
    , sharePublished =
        "共有は公開中ですが、最大表示回数に達しました。"
            ++ "この値を増やすことで、さらに表示・ダウンロードできるようにすることができます。"
    , shareNotPublished =
        "このファイルをだれかと共有する場合は、次に「公開」をしてください。"
            ++ "生成されるリンクを受け取った人はだれでもこのファイルにアクセスできます。"
    , shareLinkExpired =
        "共有を公開しましたが、現在期限切れです。"
            ++ "一度「未公開」にしてから、再度「公開」できます。"
    , errorQrCode = "QR コードの生成でエラーが発生しました。"
    , sharePublicAvailableAt = "この共有の公開 URL : "
    , shareAsYouLike = "このファイルを共有したい相手に、この URL を知らせてください。"
    , sendEmail = "メールを送る"
    , copyLink = "リンクをコピー"
    , name = "名前"
    , validity = "有効期限"
    , maxViews = "最大表示回数"
    , password = "パスワード"
    , passwordProtected = "パスワード付"
    , passwordNone = "なし"
    , shareSize = "ファイル数/サイズ"
    , created = "作成日時"
    , aliasLabel = "受信箱"
    , publishedOn = "公開日時"
    , publishedUntil = "公開期限"
    , lastAccess = "最終アクセス"
    , views = "表示回数"
    , publishWithNewLink = "新しいリンクで公開する"
    , delete = "削除"
    , edit = "編集"
    , detailsMenu = "詳細"
    , shareLinkMenu = "リンクをシェア"
    , addFilesLinkMenu = "ファイルを追加"
    , editDescription = "説明を編集"
    , publish = "公開する"
    , unpublish = "未公開に戻す"
    , listView = "リスト表示"
    , cardView = "カード表示"
    , submit = "送信"
    , clear = "クリアー"
    , resume = "再開"
    , pause = "一時停止"
    , uploadsGreaterThan =
        \size ->
            "共有するファイルの合計が " ++ size ++ " より大きくならないようにしてください。"
    , waitDeleteShare = "共有を削除しています。お待ちください。"
    , loadingData = "データを読み込んでいます..."
    , dropzone = Messages.Dropzone2.ja
    , validityField = Messages.ValidityField.ja
    , passwordRequired = "要パスワード"
    , passwordInvalid = "パスワードが無効"
    , or = "または"
    , dateTime = Messages.DateFormat.formatDateTime Language.Japanese
    , initialViewLabel =
        \iv ->
            case iv of
                Data.InitialView.Listing ->
                    "リスト表示"

                Data.InitialView.Cards ->
                    "カード表示"

                Data.InitialView.Zoom ->
                    "プレビュー"
    , initialViewField = "表示の初期状態"
    }


cz : Texts
cz =
    { mailSend = Messages.MailSend.cz
    , save = "Uložit"
    , cancel = "Zrušit"
    , yourShare = "Sdílené soubory"
    , markdownInput = Messages.MarkdownInput.cz
    , shareFileList = Messages.ShareFileList.cz
    , yesNo = Messages.YesNoDimmer.cz
    , sharePublished =
        "Sdílení bylo publikováno, ale bylo dosaženo jejího maximálního počtu zobrazení. Tuto "
            ++ "vlastnost můžete zvýšit, pokud chcete, aby byla tato položka zveřejněna ještě nějakou dobu.."
    , shareNotPublished =
        "Abyste mohli tuto položku sdílet s ostatními, musíte ji zveřejnit. "
            ++ "Poté budou mít k těmto datům přístup všichni, "
            ++ "kterým vygenerovaný odkaz pošlete."
    , shareLinkExpired =
        "Sdílení bylo publikováno, ale jeho platnost již vypršelo. Musíte jej "
            ++ "nejprve zrušit a poté znovu publikovat."
    , errorQrCode = "Chyba při generování QR kódu."
    , sharePublicAvailableAt = "Soubory jsou dostupné přes QR kód níže, nebo na webové adrese:"
    , shareAsYouLike = "Tento odkaz můžete sdílet se všemi, kteří mají mít přístup k těmto datům."
    , sendEmail = "Odeslat E-Mail"
    , copyLink = "Kopírovat odkaz"
    , name = "Název"
    , validity = "Platnost"
    , maxViews = "Max. počet zobrazení"
    , password = "Heslo"
    , passwordProtected = "Chráněno heslem"
    , passwordNone = "Žádné"
    , shareSize = "#/Velikost"
    , created = "Vytvořeno"
    , aliasLabel = "Prostor"
    , publishedOn = "Zveřejněno dne"
    , publishedUntil = "Zveřejněno do"
    , lastAccess = "Poslední přístup"
    , views = "Zobrazení"
    , publishWithNewLink = "Zveřejnit s novým odkazem"
    , delete = "Smazat"
    , edit = "Editovat"
    , detailsMenu = "Detaily"
    , shareLinkMenu = "Sdílet odkaz"
    , addFilesLinkMenu = "Přidat soubory"
    , editDescription = "Upravit popis"
    , publish = "Publikovat"
    , unpublish = "Zrušit pubikování"
    , listView = "Zobrazení seznamu"
    , cardView = "Zobrazené karet"
    , submit = "Nahrát"
    , clear = "Smazat formulář"
    , resume = "Pokračovat"
    , pause = "Pozastavit"
    , uploadsGreaterThan =
        \size ->
            "Soubory nesmí být větší než " ++ size ++ "."
    , waitDeleteShare = "Mazání. Čekejte prosím."
    , loadingData = "Nahrávám soubory..."
    , dropzone = Messages.Dropzone2.cz
    , validityField = Messages.ValidityField.cz
    , passwordRequired = "Heslo vyžadováno"
    , passwordInvalid = "Chybějící heslo"
    , or = "Nebo"
    , dateTime = Messages.DateFormat.formatDateTime Language.Czech
    , initialViewLabel =
        \iv ->
            case iv of
                Data.InitialView.Listing ->
                    "Seznam"

                Data.InitialView.Cards ->
                    "Karty"

                Data.InitialView.Zoom ->
                    "Náhled"
    , initialViewField = "Výchozí zobrazení: "
    }
