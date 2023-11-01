module Messages.ShareFileList exposing
    ( Texts
    , de
    , gb
    , fr
    , ja
    )

import Messages.YesNoDimmer


type alias Texts =
    { previewNotSupported : String
    , downloadToDisk : String
    , viewInBrowser : String
    , deleteFile : String
    , fileIsIncomplete : String
    , tryUploadAgain : String
    , yesNo : Messages.YesNoDimmer.Texts
    }


gb : Texts
gb =
    { previewNotSupported = "Preview not supported"
    , downloadToDisk = "Download to disk"
    , viewInBrowser = "View in browser"
    , deleteFile = "Delete the file."
    , fileIsIncomplete = "The file is incomplete ("
    , tryUploadAgain = "%). Try uploading again."
    , yesNo = Messages.YesNoDimmer.gb
    }


de : Texts
de =
    { previewNotSupported = "Vorschau nicht unterstützt"
    , downloadToDisk = "Herunterladen"
    , viewInBrowser = "Im Browser ansehen"
    , deleteFile = "Datei löschen."
    , fileIsIncomplete = "Die Datei ist unvollständig ("
    , tryUploadAgain = "%). Versuchen Sie erneut hochzuladen."
    , yesNo = Messages.YesNoDimmer.de
    }

fr : Texts
fr =
    { previewNotSupported = "Prévisualisation non supportée"
    , downloadToDisk = "Télécharger"
    , viewInBrowser = "Prévisualisation"
    , deleteFile = "Supprimer le fichier."
    , fileIsIncomplete = "Le fichier est incomplet ("
    , tryUploadAgain = "%). Essayer à nouveau."
    , yesNo = Messages.YesNoDimmer.fr
    }


ja : Texts
ja =
    { previewNotSupported = "プレビュー未対応"
    , downloadToDisk = "ダウンロード"
    , viewInBrowser = "ブラウザで表示"
    , deleteFile = "ファイルを削除"
    , fileIsIncomplete = "ファイルが不完全です。 ( "
    , tryUploadAgain = "% )。再度アップロードしてください。"
    , yesNo = Messages.YesNoDimmer.ja
    }
