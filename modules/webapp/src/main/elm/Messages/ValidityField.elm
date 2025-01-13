module Messages.ValidityField exposing
    ( Texts
    , de
    , gb
    , fr
    , ja
    , cz
    , es
	, it
    )

import Messages.FixedDropdown


type alias Texts =
    { dropdown : Messages.FixedDropdown.Texts
    , hour : String
    , hours : String
    , day : String
    , days : String
    , week : String
    , weeks : String
    , month : String
    , months : String
    }

it : Texts
it =
    { dropdown = Messages.FixedDropdown.it
    , hour = "ora"
    , hours = "ore"
    , day = "giorno"
    , days = "giorni"
    , week = "settimana"
    , weeks = "settimane"
    , month = "mese"
    , months = "mesi"
    }

es : Texts
es =
    { dropdown = Messages.FixedDropdown.es
    , hour = "hora"
    , hours = "horas"
    , day = "día"
    , days = "días"
    , week = "semana"
    , weeks = "semanas"
    , month = "mes"
    , months = "meses"
    }


gb : Texts
gb =
    { dropdown = Messages.FixedDropdown.gb
    , hour = "hour"
    , hours = "hours"
    , day = "day"
    , days = "days"
    , week = "week"
    , weeks = "weeks"
    , month = "month"
    , months = "months"
    }


de : Texts
de =
    { dropdown = Messages.FixedDropdown.de
    , hour = "Stunde"
    , hours = "Stunden"
    , day = "Tag"
    , days = "Tage"
    , week = "Woche"
    , weeks = "Wochen"
    , month = "Monat"
    , months = "Monate"
    }

fr : Texts
fr =
    { dropdown = Messages.FixedDropdown.fr
    , hour = "heure"
    , hours = "heures"
    , day = "jour"
    , days = "jours"
    , week = "semaine"
    , weeks = "semaines"
    , month = "mois"
    , months = "mois"
    }


ja : Texts
ja =
    { dropdown = Messages.FixedDropdown.ja
    , hour = "時間"
    , hours = "時間"
    , day = "日間"
    , days = "日間"
    , week = "週間"
    , weeks = "週間"
    , month = "カ月間"
    , months = "カ月間"
    }


cz : Texts
cz =
    { dropdown = Messages.FixedDropdown.cz
    , hour = "hodina"
    , hours = "hodiny"
    , day = "den"
    , days = "dní"
    , week = "týden"
    , weeks = "týdnů"
    , month = "měsíc"
    , months = "měsíců"
    }
