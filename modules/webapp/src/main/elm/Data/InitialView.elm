module Data.InitialView exposing (InitialView(..), all, default, fromInt, get, icon, toInt)


type InitialView
    = Listing
    | Cards
    | Zoom


all : List InitialView
all =
    [ Listing, Cards, Zoom ]


toInt : InitialView -> Int
toInt view =
    case view of
        Listing ->
            1

        Cards ->
            2

        Zoom ->
            3


default : InitialView
default =
    Listing


fromInt : Int -> Maybe InitialView
fromInt n =
    List.filter (\e -> toInt e == n) all |> List.head


get : Maybe Int -> InitialView
get n =
    Maybe.andThen fromInt n |> Maybe.withDefault default


icon : InitialView -> String
icon iv =
    case iv of
        Listing ->
            "fa fa-list"

        Cards ->
            "fa fa-th"

        Zoom ->
            "fa fa-eye"
