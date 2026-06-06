module Messages.ShareFileList exposing
    ( Texts
    , de
    , gb
    , fr
    , ja
    , cz
    , es
    , it
    )

import Messages.YesNoDimmer


type alias Texts =
    { previewNotSupported : String
    , downloadToDisk : String
    , downloadAllZip : String
    , viewInBrowser : String
    , deleteFile : String
    , fileIsIncomplete : String
    , tryUploadAgain : String
    , yesNo : Messages.YesNoDimmer.Texts
    }

it : Texts
it =
    { previewNotSupported = "Anteprima non supportata"
    , downloadToDisk = "Scarica su disco"
    , downloadAllZip = "Scarica tutto come ZIP"
    , viewInBrowser = "Visualizza nel browser"
    , deleteFile = "Elimina file."
    , fileIsIncomplete = "Il file è incompleto ("
    , tryUploadAgain = "%). Prova a caricare di nuovo."
    , yesNo = Messages.YesNoDimmer.it
    }

es : Texts
es =
    { previewNotSupported = "Vista previa no soportada"
    , downloadToDisk = "Descargar al disco"
    , downloadAllZip = "Descargar todo como ZIP"
    , viewInBrowser = "Ver en el navegador"
    , deleteFile = "Eliminar el archivo."
    , fileIsIncomplete = "El archivo está incompleto ("
    , tryUploadAgain = "%). Intenta subirlo de nuevo."
    , yesNo = Messages.YesNoDimmer.es
    }


gb : Texts
gb =
    { previewNotSupported = "Preview not supported"
    , downloadToDisk = "Download to disk"
    , downloadAllZip = "Download all as ZIP"
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
    , downloadAllZip = "Alles als ZIP herunterladen"
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
    , downloadAllZip = "Tout télécharger en ZIP"
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
    , downloadAllZip = "すべてZIPでダウンロード"
    , viewInBrowser = "ブラウザで表示"
    , deleteFile = "ファイルを削除"
    , fileIsIncomplete = "ファイルが不完全です。 ( "
    , tryUploadAgain = "% )。再度アップロードしてください。"
    , yesNo = Messages.YesNoDimmer.ja
    }

cz : Texts
cz =
    { previewNotSupported = "Náhled není podporován"
    , downloadToDisk = "Stáhnout na disk"
    , downloadAllZip = "Stáhnout vše jako ZIP"
    , viewInBrowser = "Zobrazit v prohlížeči"
    , deleteFile = "Smazat soubor."
    , fileIsIncomplete = "Soubor nebyl nahrán celý ("
    , tryUploadAgain = "%). Nahrajte jej prosím znovu."
    , yesNo = Messages.YesNoDimmer.cz
    }
