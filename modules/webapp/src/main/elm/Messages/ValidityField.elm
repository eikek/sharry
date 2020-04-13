module Messages.ValidityField exposing
    ( Texts
    , de
    , gb
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
