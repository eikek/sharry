module Messages.ValidityField exposing
    ( Texts
    , de
    , gb
    , fr
    , ja
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
