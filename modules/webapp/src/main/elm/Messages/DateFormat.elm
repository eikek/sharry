module Messages.DateFormat exposing (formatDateTime)

import DateFormat exposing (Token)
import DateFormat.Language as DL
import Language exposing (Language(..))
import Time
    exposing
        ( Month(..)
        , Weekday(..)
        )


type alias DateTimeMsg =
    { format : List Token
    , lang : DL.Language
    }


get : Language -> DateTimeMsg
get lang =
    case lang of
        English ->
            gb

        German ->
            de

        French ->
            fr

        Japanese ->
            ja

formatDateTime : Language -> Int -> String
formatDateTime lang millis =
    let
        msg =
            get lang

        fmt =
            DateFormat.formatWithLanguage msg.lang msg.format
    in
    fmt Time.utc (Time.millisToPosix millis)



--- Language Definitions


gb : DateTimeMsg
gb =
    { format =
        [ DateFormat.dayOfWeekNameAbbreviated
        , DateFormat.text ", "
        , DateFormat.monthNameFull
        , DateFormat.text " "
        , DateFormat.dayOfMonthSuffix
        , DateFormat.text ", "
        , DateFormat.yearNumber
        , DateFormat.text ", "
        , DateFormat.hourMilitaryNumber
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        ]
    , lang = DL.english
    }


de : DateTimeMsg
de =
    { format =
        [ DateFormat.dayOfWeekNameAbbreviated
        , DateFormat.text ", "
        , DateFormat.dayOfMonthSuffix
        , DateFormat.text " "
        , DateFormat.monthNameFull
        , DateFormat.text " "
        , DateFormat.yearNumber
        , DateFormat.text ", "
        , DateFormat.hourMilitaryNumber
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        ]
    , lang = german
    }


fr : DateTimeMsg
fr =
    { format =
        [ DateFormat.dayOfWeekNameAbbreviated
        , DateFormat.text ". "
        , DateFormat.dayOfMonthSuffix
        , DateFormat.text " "
        , DateFormat.monthNameFull
        , DateFormat.text " "
        , DateFormat.yearNumber
        , DateFormat.text ", "
        , DateFormat.hourMilitaryNumber
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        ]
    , lang = french
    }


ja : DateTimeMsg
ja =
    { format =
        [ DateFormat.yearNumber
        , DateFormat.text "年 "
        , DateFormat.monthNameFull
        , DateFormat.text " "
        , DateFormat.dayOfMonthNumber
        , DateFormat.text "日"
        , DateFormat.dayOfWeekNameAbbreviated
        , DateFormat.text " "
        , DateFormat.hourMilitaryNumber
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        ]
    , lang = japanese
    }

--- Languages for the DateFormat module
-- French


{-| The French language!
-}
french : DL.Language
french =
    DL.Language
        toFrenchMonthName
        toFrenchMonthAbbreviation
        toFrenchWeekdayName
        (toFrenchWeekdayName >> String.left 3)
        toEnglishAmPm
        toFrenchOrdinalSuffix


toFrenchMonthName : Month -> String
toFrenchMonthName month =
    case month of
        Jan ->
            "janvier"

        Feb ->
            "février"

        Mar ->
            "mars"

        Apr ->
            "avril"

        May ->
            "mai"

        Jun ->
            "juin"

        Jul ->
            "juillet"

        Aug ->
            "août"

        Sep ->
            "septembre"

        Oct ->
            "octobre"

        Nov ->
            "novembre"

        Dec ->
            "décembre"


toFrenchMonthAbbreviation : Month -> String
toFrenchMonthAbbreviation month =
    case month of
        Jan ->
            "janv"

        Feb ->
            "févr"

        Mar ->
            "mars"

        Apr ->
            "avr"

        May ->
            "mai"

        Jun ->
            "juin"

        Jul ->
            "juil"

        Aug ->
            "août"

        Sep ->
            "sept"

        Oct ->
            "oct"

        Nov ->
            "nov"

        Dec ->
            "déc"


toFrenchWeekdayName : Weekday -> String
toFrenchWeekdayName weekday =
    case weekday of
        Mon ->
            "lundi"

        Tue ->
            "mardi"

        Wed ->
            "mercredi"

        Thu ->
            "jeudi"

        Fri ->
            "vendredi"

        Sat ->
            "samedi"

        Sun ->
            "dimanche"


toFrenchOrdinalSuffix : Int -> String
toFrenchOrdinalSuffix n =
    if n == 1 then
        "er"

    else
        ""



-- German


{-| The German language!
-}
german : DL.Language
german =
    let
        withDot str =
            str ++ "."
    in
    DL.Language
        toGermanMonthName
        (toGermanMonthName >> String.left 3 >> withDot)
        toGermanWeekdayName
        (toGermanWeekdayName >> String.left 2 >> withDot)
        toEnglishAmPm
        (\_ -> ".")


toGermanMonthName : Month -> String
toGermanMonthName month =
    case month of
        Jan ->
            "Januar"

        Feb ->
            "Februar"

        Mar ->
            "März"

        Apr ->
            "April"

        May ->
            "Mai"

        Jun ->
            "Juni"

        Jul ->
            "Juli"

        Aug ->
            "August"

        Sep ->
            "September"

        Oct ->
            "Oktober"

        Nov ->
            "November"

        Dec ->
            "Dezember"


toGermanWeekdayName : Weekday -> String
toGermanWeekdayName weekday =
    case weekday of
        Mon ->
            "Montag"

        Tue ->
            "Dienstag"

        Wed ->
            "Mittwoch"

        Thu ->
            "Donnerstag"

        Fri ->
            "Freitag"

        Sat ->
            "Samstag"

        Sun ->
            "Sonntag"

-- Japanese
{-| The Japanese language!
-}
japanese : DL.Language
japanese =
    let
        withoutDot str =
            str ++ ""
    in
    DL.Language
        toJapaneseMonthName
        (toJapaneseMonthName >> String.left 3 >> withoutDot)
        toJapaneseWeekdayName
        (toJapaneseWeekdayName >> String.left 3 >> withoutDot)
        toEnglishAmPm
        (\_ -> ".")
toJapaneseMonthName : Month -> String
toJapaneseMonthName month =
    case month of
        Jan ->
            "1月"

        Feb ->
            "2月"

        Mar ->
            "3月"

        Apr ->
            "4月"

        May ->
            "5月"

        Jun ->
            "6月"

        Jul ->
            "7月"

        Aug ->
            "8月"

        Sep ->
            "9月"

        Oct ->
            "10月"

        Nov ->
            "11月"

        Dec ->
            "12月"

toJapaneseWeekdayName : Weekday -> String
toJapaneseWeekdayName weekday =
    case weekday of
        Mon ->
            "(月)"

        Tue ->
            "(火)"

        Wed ->
            "(水)"

        Thu ->
            "(木)"

        Fri ->
            "(金)"

        Sat ->
            "(土)"

        Sun ->
            "(日)"


--- Copy from DateFormat.Language


toEnglishAmPm : Int -> String
toEnglishAmPm hour =
    if hour > 11 then
        "pm"

    else
        "am"
