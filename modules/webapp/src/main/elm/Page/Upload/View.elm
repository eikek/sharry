module Page.Upload.View exposing (view)

import Comp.MenuBar as MB
import Comp.ShareTable
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.UploadPage exposing (Texts)
import Page exposing (Page(..))
import Page.Upload.Data exposing (Model, Msg(..))
import Styles as S
import Util.Size


view : Texts -> Model -> Html Msg
view texts model =
    div
        [ class S.content
        ]
        (viewList texts model)


viewList : Texts -> Model -> List (Html Msg)
viewList texts model =
    let
        allSize =
            List.map .size model.searchResult
                |> List.sum
                |> toFloat
                |> Util.Size.bytesReadable Util.Size.B

        count =
            List.length model.searchResult
    in
    [ h1 [ class S.header1 ]
        [ i [ class "fa fa-share-alt mr-2" ] []
        , text texts.yourShares
        , span [ class "text-sm opacity-75 ml-1" ]
            [ text ("#" ++ String.fromInt count ++ "/" ++ allSize)
            ]
        ]
    , searchArea texts model
    , Html.map ShareTableMsg
        (Comp.ShareTable.view texts.shareTable
            model.searchResult
            model.tableModel
        )
    ]


searchArea : Texts -> Model -> Html Msg
searchArea texts model =
    MB.view
        { start =
            [ MB.TextInput
                { tagger = SetQuery
                , value = model.query
                , placeholder = texts.search
                , icon = Just "fa fa-search"
                }
            ]
        , end =
            [ MB.PrimaryButton
                { tagger = InitNewShare
                , title = texts.newShare
                , icon = Just "fa fa-plus"
                , label = texts.newShare
                }
            ]
        , rootClasses = "mb-4"
        , sticky = True
        }
