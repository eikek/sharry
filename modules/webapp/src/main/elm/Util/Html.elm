module Util.Html exposing
    ( KeyCode(..)
    , checkbox
    , checkboxChecked
    , checkboxUnchecked
    , noElement
    , onDragEnter
    , onDragLeave
    , onDragOver
    , onDropFiles
    , onFiles
    , onKeyUpCode
    , resultMsg
    , resultMsgMaybe
    )

import Api.Model.BasicResult exposing (BasicResult)
import File exposing (File)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (keyCode, on, preventDefaultOn)
import Json.Decode as D
import Styles as S


checkboxChecked : Html msg
checkboxChecked =
    i [ class "fa fa-check-square font-thin" ] []


checkboxUnchecked : Html msg
checkboxUnchecked =
    i [ class "fa fa-minus-square font-thin" ] []


checkbox : Bool -> Html msg
checkbox flag =
    if flag then
        checkboxChecked

    else
        checkboxUnchecked


noElement : Html msg
noElement =
    span [ class "hidden" ] []


resultMsg : BasicResult -> Html msg
resultMsg result =
    resultMsgMaybe (Just result)


resultMsgMaybe : Maybe BasicResult -> Html msg
resultMsgMaybe mres =
    div
        [ classList
            [ ( " hidden", mres == Nothing )
            , ( S.errorMessage, Maybe.map .success mres == Just False )
            , ( S.successMessage, Maybe.map .success mres == Just True )
            ]
        ]
        [ Maybe.map .message mres
            |> Maybe.withDefault ""
            |> text
        ]


type KeyCode
    = Up
    | Down
    | Left
    | Right
    | Enter
    | Space
    | ESC
    | Letter_C
    | Letter_N
    | Letter_P
    | Letter_H
    | Letter_J
    | Letter_K
    | Letter_L
    | Letter_U
    | Point
    | Comma
    | Shift
    | Ctrl
    | Super
    | Code Int


intToKeyCode : Int -> Maybe KeyCode
intToKeyCode code =
    case code of
        16 ->
            Just Shift

        17 ->
            Just Ctrl

        91 ->
            Just Super

        38 ->
            Just Up

        40 ->
            Just Down

        39 ->
            Just Right

        37 ->
            Just Left

        13 ->
            Just Enter

        32 ->
            Just Space

        27 ->
            Just ESC

        67 ->
            Just Letter_C

        72 ->
            Just Letter_H

        74 ->
            Just Letter_J

        75 ->
            Just Letter_K

        76 ->
            Just Letter_L

        78 ->
            Just Letter_N

        80 ->
            Just Letter_P

        85 ->
            Just Letter_U

        188 ->
            Just Comma

        190 ->
            Just Point

        n ->
            Just (Code n)


onKeyUp : (Int -> msg) -> Attribute msg
onKeyUp tagger =
    on "keyup" (D.map tagger keyCode)


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (D.map tagger keyCode)


onKeyUpCode : (Maybe KeyCode -> msg) -> Attribute msg
onKeyUpCode tagger =
    onKeyUp (intToKeyCode >> tagger)


onKeyDownCode : (Maybe KeyCode -> msg) -> Attribute msg
onKeyDownCode tagger =
    onKeyDown (intToKeyCode >> tagger)


onClickk : msg -> Attribute msg
onClickk msg =
    Html.Events.preventDefaultOn "click" (D.map alwaysPreventDefault (D.succeed msg))


alwaysPreventDefault : msg -> ( msg, Bool )
alwaysPreventDefault msg =
    ( msg, True )


onDragEnter : msg -> Attribute msg
onDragEnter m =
    hijackOn "dragenter" (D.succeed m)


onDragOver : msg -> Attribute msg
onDragOver m =
    hijackOn "dragover" (D.succeed m)


onDragLeave : msg -> Attribute msg
onDragLeave m =
    hijackOn "dragleave" (D.succeed m)


onDrop : msg -> Attribute msg
onDrop m =
    hijackOn "drop" (D.succeed m)



-- onDropFiles : (File -> List File -> msg) -> Attribute msg
-- onDropFiles tagger =
--     let
--         dropFilesDecoder =
--             D.at [ "dataTransfer", "files" ] (D.oneOrMore tagger File.decoder)
--     in
--     hijackOn "drop" dropFilesDecoder


onFiles : (List ( D.Value, File ) -> msg) -> Attribute msg
onFiles tomsg =
    let
        decmsg =
            D.at [ "target", "files" ] (D.list (attach File.decoder))
                |> D.map tomsg
    in
    hijackOn "change" decmsg


onDropFiles : (List ( D.Value, File ) -> msg) -> Attribute msg
onDropFiles tagger =
    let
        dropDecoder : D.Decoder msg
        dropDecoder =
            D.at [ "dataTransfer", "files" ] (D.list (attach File.decoder))
                |> D.map tagger
    in
    hijackOn "drop" dropDecoder


attach : D.Decoder a -> D.Decoder ( D.Value, a )
attach deca =
    let
        mkTuple v =
            D.map (Tuple.pair v) deca
    in
    D.andThen mkTuple D.value


hijackOn : String -> D.Decoder msg -> Attribute msg
hijackOn event decoder =
    preventDefaultOn event (D.map hijack decoder)


hijack : msg -> ( msg, Bool )
hijack msg =
    ( msg, True )
