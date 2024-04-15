module Messages.MailForm exposing
    ( Texts
    , de
    , gb
    , fr
    , ja
    , cz
    )


type alias Texts =
    { receivers : String
    , separateRecipientsByComma : String
    , subject : String
    , body : String
    , send : String
    , cancel : String
    }


gb : Texts
gb =
    { receivers = "Receiver(s)"
    , separateRecipientsByComma = "Separate multiple recipients by comma"
    , subject = "Subject"
    , body = "Body"
    , send = "Send"
    , cancel = "Cancel"
    }


de : Texts
de =
    { receivers = "Empfänger"
    , separateRecipientsByComma = "Mehrere Empfänger durch Komma trennen"
    , subject = "Betreff"
    , body = "E-Mail Text"
    , send = "Absenden"
    , cancel = "Abbrechen"
    }

fr : Texts
fr =
    { receivers = "Destinataire(s)"
    , separateRecipientsByComma = "Séparez de multiples destinataires par une virgule"
    , subject = "Sujet"
    , body = "Corps"
    , send = "Envoi"
    , cancel = "Annulation"
    }


ja : Texts
ja =
    { receivers = "受信者"
    , separateRecipientsByComma = "複数の受信者を設定する場合は、コンマで区切る"
    , subject = "件名"
    , body = "本文"
    , send = "送信"
    , cancel = "キャンセル"
    }

cz : Texts
cz =
    { receivers = "Příjemce(i)"
    , separateRecipientsByComma = "Více příjemců oddělte čárkou"
    , subject = "Předmět"
    , body = "Tělo"
    , send = "Odeslat"
    , cancel = "Storno"
    }

