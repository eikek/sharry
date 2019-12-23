module Util.Html exposing
    ( checkbox
    , checkboxChecked
    , checkboxUnchecked
    , noElement
    , resultMsg
    , resultMsgMaybe
    )

import Api.Model.BasicResult exposing (BasicResult)
import Html exposing (..)
import Html.Attributes exposing (..)


checkboxChecked : Html msg
checkboxChecked =
    i [ class "ui check square outline icon" ] []


checkboxUnchecked : Html msg
checkboxUnchecked =
    i [ class "ui square outline icon" ] []


checkbox : Bool -> Html msg
checkbox flag =
    if flag then
        checkboxChecked

    else
        checkboxUnchecked


noElement : Html msg
noElement =
    span [ class "invisible" ] []


resultMsg : BasicResult -> Html msg
resultMsg result =
    resultMsgMaybe (Just result)


resultMsgMaybe : Maybe BasicResult -> Html msg
resultMsgMaybe mres =
    div
        [ classList
            [ ( "ui message", True )
            , ( "invisible hidden", mres == Nothing )
            , ( "error", Maybe.map .success mres == Just False )
            , ( "success", Maybe.map .success mres == Just True )
            ]
        ]
        [ Maybe.map .message mres
            |> Maybe.withDefault ""
            |> text
        ]
