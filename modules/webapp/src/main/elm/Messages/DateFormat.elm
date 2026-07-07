module Messages.DateFormat exposing (formatDateTime, formatDateTimeShort)

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

        Czech ->
            cz

        Spanish ->
            es
        
        Italian ->
            it

        Portuguese ->
            br

formatDateTime : Language -> Time.Zone -> Int -> String
formatDateTime lang zone millis =
    let
        msg =
            get lang

        fmt =
            DateFormat.formatWithLanguage msg.lang msg.format
    in
    fmt zone (Time.millisToPosix millis)


{-| A compact, numeric date/time format (e.g. "07/07/2026, 09:19"), used where
full weekday/month names take up too much space (e.g. inline file badges).
-}
formatDateTimeShort : Language -> Time.Zone -> Int -> String
formatDateTimeShort lang zone millis =
    let
        msg =
            get lang

        format =
            case lang of
                Japanese ->
                    [ DateFormat.yearNumber
                    , DateFormat.text "/"
                    , DateFormat.monthFixed
                    , DateFormat.text "/"
                    , DateFormat.dayOfMonthFixed
                    , DateFormat.text " "
                    , DateFormat.hourMilitaryFixed
                    , DateFormat.text ":"
                    , DateFormat.minuteFixed
                    ]

                _ ->
                    [ DateFormat.dayOfMonthFixed
                    , DateFormat.text "/"
                    , DateFormat.monthFixed
                    , DateFormat.text "/"
                    , DateFormat.yearNumber
                    , DateFormat.text ", "
                    , DateFormat.hourMilitaryFixed
                    , DateFormat.text ":"
                    , DateFormat.minuteFixed
                    ]

        fmt =
            DateFormat.formatWithLanguage msg.lang format
    in
    fmt zone (Time.millisToPosix millis)



--- Language Definitions

it : DateTimeMsg
it =
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
    , lang = italian
    }

es : DateTimeMsg
es =
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
    , lang = DL.spanish
    }


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


cz : DateTimeMsg
cz =
    { format =
        [ DateFormat.dayOfWeekNameAbbreviated
        , DateFormat.text ", "
        , DateFormat.dayOfMonthSuffix
        , DateFormat.text " "
        , DateFormat.monthNameFull
        , DateFormat.text ", "
        , DateFormat.yearNumber
        , DateFormat.text ", "
        , DateFormat.hourMilitaryNumber
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        ]
    , lang = czech
    }


br : DateTimeMsg
br =
    { format =
        [ DateFormat.dayOfWeekNameAbbreviated
        , DateFormat.text ", "
        , DateFormat.dayOfMonthSuffix
        , DateFormat.text " de "
        , DateFormat.monthNameFull
        , DateFormat.text " de "
        , DateFormat.yearNumber
        , DateFormat.text ", "
        , DateFormat.hourMilitaryNumber
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        ]
    , lang = portuguese
    }



--- Languages for the DateFormat module
-- Italian


{-| The Italian language!
-}
italian : DL.Language
italian =
    let
        withDot str =
            str ++ "."
    in
    DL.Language
        toItalianMonthName
        toItalianMonthAbbreviation
        toItalianWeekdayName
        (toItalianWeekdayName >> String.left 3 >> withDot)
        toEnglishAmPm
        (\_ -> ".")

toItalianMonthName : Month -> String
toItalianMonthName month =
    case month of
        Jan -> "Gennaio"
        Feb -> "Febbraio"
        Mar -> "Marzo"
        Apr -> "Aprile"
        May -> "Maggio"
        Jun -> "Giugno"
        Jul -> "Luglio"
        Aug -> "Agosto"
        Sep -> "Settembre"
        Oct -> "Ottobre"
        Nov -> "Novembre"
        Dec -> "Dicembre"

toItalianMonthAbbreviation : Month -> String
toItalianMonthAbbreviation month =
    case month of
        Jan -> "Gen"
        Feb -> "Feb"
        Mar -> "Mar"
        Apr -> "Apr"
        May -> "Mag"
        Jun -> "Giu"
        Jul -> "Lug"
        Aug -> "Ago"
        Sep -> "Set"
        Oct -> "Ott"
        Nov -> "Nov"
        Dec -> "Dic"

toItalianWeekdayName : Weekday -> String
toItalianWeekdayName weekday =
    case weekday of
        Mon -> "Lunedì"
        Tue -> "Martedì"
        Wed -> "Mercoledì"
        Thu -> "Giovedì"
        Fri -> "Venerdì"
        Sat -> "Sabato"
        Sun -> "Domenica"

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

-- Czech


{-| The Czech language!
-}
czech : DL.Language
czech =
    let
        withDot str =
            str ++ "."
    in
    DL.Language
        toCzechMonthName
        (toCzechMonthName >> String.left 3 >> withDot)
        toCzechWeekdayName
        (toCzechWeekdayName >> String.left 2 >> withDot)
        toEnglishAmPm
        (\_ -> ".")


toCzechMonthName : Month -> String
toCzechMonthName month =
    case month of
        Jan ->
            "Leden"

        Feb ->
            "Únor"

        Mar ->
            "Březen"

        Apr ->
            "Duben"

        May ->
            "Květen"

        Jun ->
            "Červen"

        Jul ->
            "Červenec"

        Aug ->
            "Srpen"

        Sep ->
            "Září"

        Oct ->
            "Říjen"

        Nov ->
            "Listopad"

        Dec ->
            "Prosinec"


toCzechWeekdayName : Weekday -> String
toCzechWeekdayName weekday =
    case weekday of
        Mon ->
            "Pondělí"

        Tue ->
            "Úterý"

        Wed ->
            "Středa"

        Thu ->
            "Čtvrtek"

        Fri ->
            "Pátek"

        Sat ->
            "Sobota"

        Sun ->
            "Neděle"

-- Portuguese (Brazil)


{-| Brazilian Portuguese language!
-}
portuguese : DL.Language
portuguese =
    let
        withDot str =
            str ++ "."
    in
    DL.Language
        toPortugueseMonthName
        toPortugueseMonthAbbreviation
        toPortugueseWeekdayName
        (toPortugueseWeekdayName >> String.left 3 >> withDot)
        toEnglishAmPm
        (\_ -> "")


toPortugueseMonthName : Month -> String
toPortugueseMonthName month =
    case month of
        Jan ->
            "janeiro"

        Feb ->
            "fevereiro"

        Mar ->
            "março"

        Apr ->
            "abril"

        May ->
            "maio"

        Jun ->
            "junho"

        Jul ->
            "julho"

        Aug ->
            "agosto"

        Sep ->
            "setembro"

        Oct ->
            "outubro"

        Nov ->
            "novembro"

        Dec ->
            "dezembro"


toPortugueseMonthAbbreviation : Month -> String
toPortugueseMonthAbbreviation month =
    case month of
        Jan ->
            "jan"

        Feb ->
            "fev"

        Mar ->
            "mar"

        Apr ->
            "abr"

        May ->
            "mai"

        Jun ->
            "jun"

        Jul ->
            "jul"

        Aug ->
            "ago"

        Sep ->
            "set"

        Oct ->
            "out"

        Nov ->
            "nov"

        Dec ->
            "dez"


toPortugueseWeekdayName : Weekday -> String
toPortugueseWeekdayName weekday =
    case weekday of
        Mon ->
            "segunda-feira"

        Tue ->
            "terça-feira"

        Wed ->
            "quarta-feira"

        Thu ->
            "quinta-feira"

        Fri ->
            "sexta-feira"

        Sat ->
            "sábado"

        Sun ->
            "domingo"



--- Copy from DateFormat.Language


toEnglishAmPm : Int -> String
toEnglishAmPm hour =
    if hour > 11 then
        "pm"

    else
        "am"
