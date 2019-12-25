module Util.Maybe exposing
    ( filter
    , fromString
    , isEmpty
    , nonEmpty
    , or
    )


nonEmpty : Maybe a -> Bool
nonEmpty ma =
    ma /= Nothing


isEmpty : Maybe a -> Bool
isEmpty ma =
    ma == Nothing


or : List (Maybe a) -> Maybe a
or listma =
    case listma of
        [] ->
            Nothing

        (Just el) :: _ ->
            Just el

        Nothing :: els ->
            or els


filter : (a -> Bool) -> Maybe a -> Maybe a
filter pred ma =
    case ma of
        Just v ->
            if pred v then
                ma

            else
                Nothing

        Nothing ->
            Nothing


fromString : String -> Maybe String
fromString str =
    let
        s =
            String.trim str
    in
    if s == "" then
        Nothing

    else
        Just str
