module Messages.ShareFileList exposing
    ( Texts
    , applyZone
    , de
    , gb
    , fr
    , ja
    , cz
    , es
    , it
    , br
    )

import Language exposing (Language)
import Messages.DateFormat
import Messages.YesNoDimmer
import Time


type alias Texts =
    { previewNotSupported : String
    , downloadToDisk : String
    , downloadAllZip : String
    , downloadSelectedZip : String
    , selectAll : String
    , deselectAll : String
    , noFilesSelected : String
    , selectionTooLarge : String
    , selectedSizeOf : String
    , viewInBrowser : String
    , deleteFile : String
    , fileIsIncomplete : String
    , tryUploadAgain : String
    , yesNo : Messages.YesNoDimmer.Texts
    , dateTime : Int -> String
    , exactSize : String
    , checksumLabel : String
    , checksumNotAvailable : String
    , copyChecksum : String
    , toggleDetails : String
    }

it : Texts
it =
    { previewNotSupported = "Anteprima non supportata"
    , downloadToDisk = "Scarica su disco"
    , downloadAllZip = "Scarica tutto come ZIP"
    , downloadSelectedZip = "Scarica selezionati come ZIP"
    , selectAll = "Seleziona tutto"
    , deselectAll = "Deseleziona tutto"
    , noFilesSelected = "Nessun file selezionato"
    , selectionTooLarge = "Selezione troppo grande per il download ZIP"
    , selectedSizeOf = " di "
    , viewInBrowser = "Visualizza nel browser"
    , deleteFile = "Elimina file."
    , fileIsIncomplete = "Il file è incompleto ("
    , tryUploadAgain = "%). Prova a caricare di nuovo."
    , yesNo = Messages.YesNoDimmer.it
    , dateTime = Messages.DateFormat.formatDateTime Language.Italian Time.utc
    , exactSize = "Dimensione esatta"
    , checksumLabel = "SHA-256"
    , checksumNotAvailable = "Non ancora calcolato"
    , copyChecksum = "Copia"
    , toggleDetails = "Dettagli file"
    }

es : Texts
es =
    { previewNotSupported = "Vista previa no soportada"
    , downloadToDisk = "Descargar al disco"
    , downloadAllZip = "Descargar todo como ZIP"
    , downloadSelectedZip = "Descargar seleccionados como ZIP"
    , selectAll = "Seleccionar todo"
    , deselectAll = "Deseleccionar todo"
    , noFilesSelected = "No hay archivos seleccionados"
    , selectionTooLarge = "Selección demasiado grande para descarga ZIP"
    , selectedSizeOf = " de "
    , viewInBrowser = "Ver en el navegador"
    , deleteFile = "Eliminar el archivo."
    , fileIsIncomplete = "El archivo está incompleto ("
    , tryUploadAgain = "%). Intenta subirlo de nuevo."
    , yesNo = Messages.YesNoDimmer.es
    , dateTime = Messages.DateFormat.formatDateTime Language.Spanish Time.utc
    , exactSize = "Tamaño exacto"
    , checksumLabel = "SHA-256"
    , checksumNotAvailable = "Aún no calculado"
    , copyChecksum = "Copiar"
    , toggleDetails = "Detalles del archivo"
    }


gb : Texts
gb =
    { previewNotSupported = "Preview not supported"
    , downloadToDisk = "Download to disk"
    , downloadAllZip = "Download all as ZIP"
    , downloadSelectedZip = "Download selected as ZIP"
    , selectAll = "Select all"
    , deselectAll = "Deselect all"
    , noFilesSelected = "No files selected"
    , selectionTooLarge = "Selection too large for ZIP download"
    , selectedSizeOf = " of "
    , viewInBrowser = "View in browser"
    , deleteFile = "Delete the file."
    , fileIsIncomplete = "The file is incomplete ("
    , tryUploadAgain = "%). Try uploading again."
    , yesNo = Messages.YesNoDimmer.gb
    , dateTime = Messages.DateFormat.formatDateTime Language.English Time.utc
    , exactSize = "Exact size"
    , checksumLabel = "SHA-256"
    , checksumNotAvailable = "Not yet computed"
    , copyChecksum = "Copy"
    , toggleDetails = "File details"
    }


de : Texts
de =
    { previewNotSupported = "Vorschau nicht unterstützt"
    , downloadToDisk = "Herunterladen"
    , downloadAllZip = "Alles als ZIP herunterladen"
    , downloadSelectedZip = "Ausgewählte als ZIP herunterladen"
    , selectAll = "Alle auswählen"
    , deselectAll = "Alle abwählen"
    , noFilesSelected = "Keine Dateien ausgewählt"
    , selectionTooLarge = "Auswahl zu groß für ZIP-Download"
    , selectedSizeOf = " von "
    , viewInBrowser = "Im Browser ansehen"
    , deleteFile = "Datei löschen."
    , fileIsIncomplete = "Die Datei ist unvollständig ("
    , tryUploadAgain = "%). Versuchen Sie erneut hochzuladen."
    , yesNo = Messages.YesNoDimmer.de
    , dateTime = Messages.DateFormat.formatDateTime Language.German Time.utc
    , exactSize = "Genaue Größe"
    , checksumLabel = "SHA-256"
    , checksumNotAvailable = "Noch nicht berechnet"
    , copyChecksum = "Kopieren"
    , toggleDetails = "Dateidetails"
    }

fr : Texts
fr =
    { previewNotSupported = "Prévisualisation non supportée"
    , downloadToDisk = "Télécharger"
    , downloadAllZip = "Tout télécharger en ZIP"
    , downloadSelectedZip = "Télécharger la sélection en ZIP"
    , selectAll = "Tout sélectionner"
    , deselectAll = "Tout désélectionner"
    , noFilesSelected = "Aucun fichier sélectionné"
    , selectionTooLarge = "Sélection trop grande pour le téléchargement ZIP"
    , selectedSizeOf = " sur "
    , viewInBrowser = "Prévisualisation"
    , deleteFile = "Supprimer le fichier."
    , fileIsIncomplete = "Le fichier est incomplet ("
    , tryUploadAgain = "%). Essayer à nouveau."
    , yesNo = Messages.YesNoDimmer.fr
    , dateTime = Messages.DateFormat.formatDateTime Language.French Time.utc
    , exactSize = "Taille exacte"
    , checksumLabel = "SHA-256"
    , checksumNotAvailable = "Pas encore calculé"
    , copyChecksum = "Copier"
    , toggleDetails = "Détails du fichier"
    }


ja : Texts
ja =
    { previewNotSupported = "プレビュー未対応"
    , downloadToDisk = "ダウンロード"
    , downloadAllZip = "すべてZIPでダウンロード"
    , downloadSelectedZip = "選択したファイルをZIPでダウンロード"
    , selectAll = "すべて選択"
    , deselectAll = "すべて選択解除"
    , noFilesSelected = "ファイルが選択されていません"
    , selectionTooLarge = "選択したファイルがZIPダウンロードの上限を超えています"
    , selectedSizeOf = " / "
    , viewInBrowser = "ブラウザで表示"
    , deleteFile = "ファイルを削除"
    , fileIsIncomplete = "ファイルが不完全です。 ( "
    , tryUploadAgain = "% )。再度アップロードしてください。"
    , yesNo = Messages.YesNoDimmer.ja
    , dateTime = Messages.DateFormat.formatDateTime Language.Japanese Time.utc
    , exactSize = "正確なサイズ"
    , checksumLabel = "SHA-256"
    , checksumNotAvailable = "まだ計算されていません"
    , copyChecksum = "コピー"
    , toggleDetails = "ファイルの詳細"
    }

cz : Texts
cz =
    { previewNotSupported = "Náhled není podporován"
    , downloadToDisk = "Stáhnout na disk"
    , downloadAllZip = "Stáhnout vše jako ZIP"
    , downloadSelectedZip = "Stáhnout vybrané jako ZIP"
    , selectAll = "Vybrat vše"
    , deselectAll = "Zrušit výběr"
    , noFilesSelected = "Žádné soubory nejsou vybrány"
    , selectionTooLarge = "Výběr je příliš velký pro stažení ZIP"
    , selectedSizeOf = " z "
    , viewInBrowser = "Zobrazit v prohlížeči"
    , deleteFile = "Smazat soubor."
    , fileIsIncomplete = "Soubor nebyl nahrán celý ("
    , tryUploadAgain = "%). Nahrajte jej prosím znovu."
    , yesNo = Messages.YesNoDimmer.cz
    , dateTime = Messages.DateFormat.formatDateTime Language.Czech Time.utc
    , exactSize = "Přesná velikost"
    , checksumLabel = "SHA-256"
    , checksumNotAvailable = "Zatím nevypočítáno"
    , copyChecksum = "Kopírovat"
    , toggleDetails = "Podrobnosti souboru"
    }

br : Texts
br =
    { previewNotSupported = "Visualização não suportada"
    , downloadToDisk = "Baixar para o disco"
    , downloadAllZip = "Baixar tudo como ZIP"
    , downloadSelectedZip = "Baixar selecionados como ZIP"
    , selectAll = "Selecionar tudo"
    , deselectAll = "Desmarcar tudo"
    , noFilesSelected = "Nenhum arquivo selecionado"
    , selectionTooLarge = "Seleção muito grande para download ZIP"
    , selectedSizeOf = " de "
    , viewInBrowser = "Ver no navegador"
    , deleteFile = "Excluir o arquivo."
    , fileIsIncomplete = "O arquivo está incompleto ("
    , tryUploadAgain = "%). Tente enviar novamente."
    , yesNo = Messages.YesNoDimmer.br
    , dateTime = Messages.DateFormat.formatDateTime Language.Portuguese Time.utc
    , exactSize = "Tamanho exato"
    , checksumLabel = "SHA-256"
    , checksumNotAvailable = "Ainda não calculado"
    , copyChecksum = "Copiar"
    , toggleDetails = "Detalhes do arquivo"
    }


applyZone : Time.Zone -> Language -> Texts -> Texts
applyZone zone lang texts =
    { texts | dateTime = Messages.DateFormat.formatDateTime lang zone }
