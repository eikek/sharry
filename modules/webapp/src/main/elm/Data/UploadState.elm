module Data.UploadState exposing
    ( FileProgress(..)
    , UploadState
    , decode
    )

import Json.Decode as D


{-| Values of this type are received from the JS side to inform about
upload state.
-}
type alias UploadState =
    { id : String
    , file : Int
    , state : FileProgress
    }


type FileProgress
    = Complete
    | Progress Int Int
    | Failed String


errorMessage : FileProgress -> Maybe String
errorMessage fp =
    case fp of
        Complete ->
            Nothing

        Progress _ _ ->
            Nothing

        Failed str ->
            Just (convertErrorMessage str)


convertErrorMessage : String -> String
convertErrorMessage str =
    if String.contains "response code: 422" str then
        String.indexes "response text:" str
            |> List.head
            |> Maybe.map ((+) 14)
            |> Maybe.map (\n -> String.slice n (String.length str - 1) str)
            |> Maybe.map String.trim
            |> Maybe.withDefault str

    else
        str


decode : D.Value -> Result String UploadState
decode json =
    D.decodeValue decoder json
        |> Result.mapError D.errorToString


decoder : D.Decoder UploadState
decoder =
    D.map3 UploadState
        (D.field "id" D.string)
        (D.field "file" D.int)
        (D.field "progress" progressDecoder)


progressDecoder : D.Decoder FileProgress
progressDecoder =
    let
        complete =
            D.map (\_ -> Complete)
                (D.field "state" (constant "complete"))

        failed =
            D.map2 (\e -> \_ -> Failed e)
                (D.map convertErrorMessage (D.field "error" D.string))
                (D.field "state" (constant "failed"))

        progress =
            D.map3 (\a -> \b -> \_ -> Progress a b)
                (D.field "uploaded" D.int)
                (D.field "total" D.int)
                (D.field "state" (constant "progress"))
    in
    D.oneOf [ complete, failed, progress ]


constant : String -> D.Decoder ()
constant str =
    let
        check s =
            if String.toLower str == s then
                D.succeed ()

            else
                D.fail ("Expected " ++ str ++ " but got: " ++ s)
    in
    D.map String.toLower D.string
        |> D.andThen check
