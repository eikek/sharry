module Data.ValidityOptions exposing
    ( findValidityItem
    , findValidityItemMillis
    , validityOptions
    )

import Data.Flags exposing (Flags)
import Data.ValidityValue exposing (ValidityValue(..))


allValidityOptions : List ( String, ValidityValue )
allValidityOptions =
    [ ( "1/2 hour", Minutes 30 )
    , ( "1 hour", Hours 1 )
    , ( "2 hours", Hours 2 )
    , ( "4 hours", Hours 4 )
    , ( "8 hours", Hours 8 )
    , ( "16 hours", Hours 16 )
    , ( "1 day", Days 1 )
    , ( "2 days", Days 2 )
    , ( "4 days", Days 4 )
    , ( "1 week", Days 7 )
    , ( "2 weeks", Days 14 )
    , ( "1 month", Days 30 )
    , ( "2 months", Days 60 )
    , ( "4 months", Days <| 4 * 30 )
    , ( "8 months", Days <| 8 * 30 )
    , ( "12 months", Days 365 )
    ]


validityOptions : Flags -> List ( String, ValidityValue )
validityOptions flags =
    let
        fun ( _, v ) =
            Data.ValidityValue.toMillis v <= flags.config.maxValidity
    in
    List.filter fun allValidityOptions


defaultValidity : ( String, ValidityValue )
defaultValidity =
    ( "2 days", Days 2 )


findValidityItemMillis : Int -> ( String, ValidityValue )
findValidityItemMillis millis =
    findValidityItem (Millis millis)


{-| Finds the item from the list of options that best matches the
given validity value.
-}
findValidityItem : ValidityValue -> ( String, ValidityValue )
findValidityItem vv =
    let
        ld =
            List.repeat (List.length allValidityOptions) vv

        diff t a =
            ( Data.ValidityValue.sub (Tuple.second t) a |> abs, t )
    in
    List.map2 diff allValidityOptions ld
        |> findMinimum
        |> Maybe.map Tuple.second
        |> Maybe.withDefault defaultValidity


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
