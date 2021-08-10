module Page.Home.View exposing (view)

import Comp.Basic as B
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.HomePage exposing (Texts)
import Page exposing (Page(..))
import Page.Home.Data exposing (Model)
import Styles as S


view : Texts -> Model -> Html msg
view texts _ =
    div
        [ class "h-full md:h-5/6 flex flex-col justify-center items-center"
        ]
        [ div
            [ class "w-full px-4 py-4 mt-2 flex flex-col items-center"
            , class "md:w-2/3 md:mx-auto md:bg-gray-100 md:mt-8 md:px-8 md:py-8 md:shadow md:rounded-lg"
            , class "md:dark:bg-warmgray-700"
            ]
            [ div [ class "flex flex-col items-center text-4xl" ]
                [ i [ class "fa fa-share-alt" ] []
                , span [ class "mt-2 w-full text-center" ]
                    [ text texts.shareFilesWithOthers
                    ]
                ]
            , div [ class "flex flex-col sm:flex-row justify-center w-full mt-8" ]
                [ div [ class "flex flex-col sm:mr-2" ]
                    [ B.primaryButton
                        { label = texts.createShare
                        , icon = "fa fa-upload"
                        , handler = class "text-xl sm:text-base"
                        , disabled = False
                        , attrs =
                            [ Page.href SharePage
                            ]
                        , responsive = False
                        }
                    , B.secondaryButton
                        { label = texts.viewShares
                        , icon = "fa fa-eye"
                        , handler = class "mt-2 text-xl sm:text-base"
                        , disabled = False
                        , attrs =
                            [ Page.href UploadPage
                            ]
                        , responsive = False
                        }
                    ]
                , div [ class "mt-2 sm:mt-0 sm:ml-2 flex flex-col " ]
                    [ B.primaryButton
                        { label = texts.createAlias
                        , icon = "fa fa-dot-circle font-thin"
                        , handler = class "text-xl sm:text-base"
                        , disabled = False
                        , attrs =
                            [ Page.href (AliasPage (Just "new"))
                            ]
                        , responsive = False
                        }
                    , B.secondaryButton
                        { label = texts.viewAliases
                        , icon = "fa fa-eye"
                        , handler = class "mt-2 text-xl sm:text-base"
                        , disabled = False
                        , attrs =
                            [ Page.href (AliasPage Nothing)
                            ]
                        , responsive = False
                        }
                    ]
                ]
            ]
        , div [ class "text-xs mt-2" ]
            [ a
                [ class S.link
                , href "https://eikek.github.io/sharry/doc/webapp"
                , target "_blank"
                ]
                [ i [ class "fa fa-external-link-alt mr-1" ] []
                , text texts.documentation
                ]
            ]
        ]
