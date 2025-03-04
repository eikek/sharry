module Data.ValidityOptions exposing
    ( defaultValidity
    , findValidityItem
    , findValidityItemMillis
    , validityOptions
    )

import Data.Flags exposing (Flags)
import Data.ValidityValue exposing (ValidityValue(..))
import Messages
import Messages.ValidityField exposing (Texts)


allValidityOptions : Texts -> List ( String, ValidityValue )
allValidityOptions texts =
    [ ( "1/2 " ++ texts.hour, Minutes 30 )
    , ( "1 " ++ texts.hour, Hours 1 )
    , ( "2 " ++ texts.hours, Hours 2 )
    , ( "4 " ++ texts.hours, Hours 4 )
    , ( "8 " ++ texts.hours, Hours 8 )
    , ( "16 " ++ texts.hours, Hours 16 )
    , ( "1 " ++ texts.day, Days 1 )
    , ( "2 " ++ texts.days, Days 2 )
    , ( "4 " ++ texts.days, Days 4 )
    , ( "1 " ++ texts.week, Days 7 )
    , ( "2 " ++ texts.weeks, Days 14 )
    , ( "1 " ++ texts.month, Days 30 )
    , ( "2 " ++ texts.months, Days 60 )
    , ( "4 " ++ texts.months, Days <| 4 * 30 )
    , ( "8 " ++ texts.months, Days <| 8 * 30 )
    , ( "12 " ++ texts.months, Days 365 )
    , ( "24 " ++ texts.months, Days 730 )
    , ( "36 " ++ texts.months, Days 1095 )
    , ( "120 " ++ texts.months, Days 3652 )
    , ( "1200 " ++ texts.months, Days 36525 )
    ]


validityOptions : Flags -> List ( String, ValidityValue )
validityOptions flags =
    let
        m =
            Messages.fromFlags flags

        texts =
            m.detail.validityField

        fun ( _, v ) =
            Data.ValidityValue.toMillis v <= flags.config.maxValidity
    in
    List.filter fun (allValidityOptions texts)


defaultValidity : Flags -> ( String, ValidityValue )
defaultValidity flags =
    let
        findDefault ( _, v ) =
            Data.ValidityValue.toMillis v == flags.config.defaultValidity
    in
    List.filter findDefault (validityOptions flags)
        |> List.head
        |> Maybe.withDefault ( "2x days", Days 2 )


findValidityItemMillis : Texts -> Flags -> Int -> ( String, ValidityValue )
findValidityItemMillis texts flags millis =
    findValidityItem texts flags (Millis millis)


{-| Finds the item from the list of options that best matches the
given validity value.
-}
findValidityItem : Texts -> Flags -> ValidityValue -> ( String, ValidityValue )
findValidityItem texts flags vv =
    let
        ld =
            List.repeat (List.length <| allValidityOptions texts) vv

        diff t a =
            ( Data.ValidityValue.sub (Tuple.second t) a |> abs, t )

        defaultValue =
            defaultValidity flags
    in
    List.map2 diff (allValidityOptions texts) ld
        |> findMinimum
        |> Maybe.map Tuple.second
        |> Maybe.withDefault defaultValue


findMinimum :
    List ( Int, ( String, ValidityValue ) )
    -> Maybe ( Int, ( String, ValidityValue ) )
findMinimum list =
    case list of
        [] ->
            Nothing

        x :: xs ->
            let
                getmin :
                    ( Int, ( String, ValidityValue ) )
                    -> ( Int, ( String, ValidityValue ) )
                    -> ( Int, ( String, ValidityValue ) )
                getmin a b =
                    if Tuple.first a < Tuple.first b then
                        a

                    else
                        b
            in
            Just (List.foldl getmin x xs)
