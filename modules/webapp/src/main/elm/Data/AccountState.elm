module Data.AccountState exposing
    ( AccountState(..)
    , all
    , fromString
    , fromStringDefault
    , fromStringOrActive
    , toString
    )


type AccountState
    = Active
    | Disabled


fromString : String -> Maybe AccountState
fromString str =
    case String.toLower str of
        "active" ->
            Just Active

        "disabled" ->
            Just Disabled

        _ ->
            Nothing


fromStringDefault : AccountState -> String -> AccountState
fromStringDefault default str =
    fromString str
        |> Maybe.withDefault default


fromStringOrActive : String -> AccountState
fromStringOrActive str =
    fromStringDefault Active str


toString : AccountState -> String
toString state =
    case state of
        Active ->
            "Active"

        Disabled ->
            "Disabled"


all : List AccountState
all =
    [ Active, Disabled ]
