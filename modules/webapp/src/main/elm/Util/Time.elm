module Util.Time exposing
    ( formatDateTime
    , timeZone
    )

import DateFormat
import Time exposing (Posix, Zone, utc)


dateTimeFormatter : Zone -> Posix -> String
dateTimeFormatter =
    DateFormat.format
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


timeZone : Zone
timeZone =
    utc


formatDateTime : Int -> String
formatDateTime millis =
    Time.millisToPosix millis
        |> dateTimeFormatter timeZone
