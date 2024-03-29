module Comp.Basic exposing
    ( editLinkLabel
    , editLinkTableCell
    , genericButton
    , horizontalDivider
    , inputRequired
    , linkLabel
    , loadingDimmer
    , primaryBasicButton
    , primaryButton
    , secondaryBasicButton
    , secondaryButton
    , showLinkTableCell
    , stats
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Styles as S


primaryButton :
    { x
        | label : String
        , icon : String
        , disabled : Bool
        , handler : Attribute msg
        , attrs : List (Attribute msg)
        , responsive : Bool
    }
    -> Html msg
primaryButton model =
    genericButton
        { label = model.label
        , icon = model.icon
        , handler = model.handler
        , disabled = model.disabled
        , attrs = model.attrs
        , baseStyle = S.primaryButtonMain ++ S.primaryButtonRounded
        , activeStyle = S.primaryButtonHover
        , responsive = model.responsive
        }


primaryBasicButton :
    { x
        | label : String
        , icon : String
        , disabled : Bool
        , handler : Attribute msg
        , attrs : List (Attribute msg)
        , responsive : Bool
    }
    -> Html msg
primaryBasicButton model =
    genericButton
        { label = model.label
        , icon = model.icon
        , handler = model.handler
        , disabled = model.disabled
        , attrs = model.attrs
        , baseStyle = S.primaryBasicButtonMain
        , activeStyle = S.primaryBasicButtonHover
        , responsive = model.responsive
        }


secondaryButton :
    { x
        | label : String
        , icon : String
        , disabled : Bool
        , handler : Attribute msg
        , attrs : List (Attribute msg)
        , responsive : Bool
    }
    -> Html msg
secondaryButton model =
    genericButton
        { label = model.label
        , icon = model.icon
        , handler = model.handler
        , disabled = model.disabled
        , attrs = model.attrs
        , baseStyle = S.secondaryButtonMain
        , activeStyle = S.secondaryButtonHover
        , responsive = model.responsive
        }


secondaryBasicButton :
    { x
        | label : String
        , icon : String
        , disabled : Bool
        , handler : Attribute msg
        , attrs : List (Attribute msg)
        , responsive : Bool
    }
    -> Html msg
secondaryBasicButton model =
    genericButton
        { label = model.label
        , icon = model.icon
        , handler = model.handler
        , disabled = model.disabled
        , attrs = model.attrs
        , baseStyle = S.secondaryBasicButtonMain ++ S.secondaryBasicButtonRounded
        , activeStyle = S.secondaryBasicButtonHover
        , responsive = model.responsive
        }


genericButton :
    { x
        | label : String
        , icon : String
        , disabled : Bool
        , handler : Attribute msg
        , attrs : List (Attribute msg)
        , baseStyle : String
        , activeStyle : String
        , responsive : Bool
    }
    -> Html msg
genericButton model =
    let
        attrs =
            if model.disabled then
                [ class model.baseStyle
                , class "disabled"
                , href "#"
                ]
                    ++ model.attrs

            else
                [ class model.baseStyle
                , class model.activeStyle
                , model.handler
                ]
                    ++ model.attrs
    in
    genericLink model.responsive model.icon model.label attrs


linkLabel :
    { x
        | disabled : Bool
        , label : String
        , icon : String
        , handler : msg
        , style :
            { plain : String
            , hover : String
            }
    }
    -> Html msg
linkLabel model =
    let
        styles =
            [ class "label"
            , class "inline-block md:text-sm my-auto whitespace-nowrap"
            , class model.style.plain
            ]

        hover =
            [ class model.style.hover
            ]

        attrs =
            if model.disabled then
                [ href "#"
                , class "disabled"
                ]
                    ++ styles

            else
                [ onClick model.handler
                , href "#"
                ]
                    ++ styles
                    ++ hover
    in
    genericLink False model.icon model.label attrs


loadingDimmer : { label : String, active : Bool } -> Html msg
loadingDimmer cfg =
    div
        [ classList
            [ ( "hidden", not cfg.active )
            ]
        , class S.dimmer
        ]
        [ div [ class "text-gray-200" ]
            [ i [ class "fa fa-circle-notch animate-spin" ] []
            , span [ class "ml-2" ]
                [ text cfg.label
                ]
            ]
        ]


editLinkLabel : String -> msg -> Html msg
editLinkLabel label click =
    linkLabel
        { label = label
        , icon = "fa fa-edit"
        , handler = click
        , disabled = False
        , style =
            { plain =
                "border-blue-500 text-blue-500 "
                    ++ "dark:border-orange-500 dark:text-orange-500"
            , hover =
                "hover:bg-blue-500 hover:text-gray-100 "
                    ++ "dark:hover:bg-orange-500 dark:hover:text-stone-900"
            }
        }


showLinkLabel : String -> msg -> Html msg
showLinkLabel label click =
    linkLabel
        { label = label
        , icon = "fa fa-eye"
        , handler = click
        , disabled = False
        , style =
            { plain =
                "border-blue-500 text-blue-500 "
                    ++ "dark:border-orange-500 dark:text-orange-500"
            , hover =
                "hover:bg-blue-500 hover:text-gray-100 "
                    ++ "dark:hover:bg-orange-500 dark:hover:text-stone-900"
            }
        }


editLinkTableCell : String -> msg -> Html msg
editLinkTableCell label m =
    td [ class S.editLinkTableCellStyle ]
        [ editLinkLabel label m
        ]


showLinkTableCell : String -> msg -> Html msg
showLinkTableCell label m =
    td [ class S.editLinkTableCellStyle ]
        [ showLinkLabel label m
        ]


stats :
    { x
        | valueClass : String
        , rootClass : String
        , value : String
        , label : String
    }
    -> Html msg
stats model =
    div
        [ class "flex flex-col mx-6"
        , class model.rootClass
        ]
        [ div
            [ class "uppercase text-center"
            , class model.valueClass
            ]
            [ text model.value
            ]
        , div [ class "text-center uppercase font-semibold" ]
            [ text model.label
            ]
        ]


horizontalDivider :
    { label : String
    , topCss : String
    , labelCss : String
    , lineColor : String
    }
    -> Html msg
horizontalDivider settings =
    div [ class "inline-flex items-center", class settings.topCss ]
        [ div
            [ class "h-px flex-grow"
            , class settings.lineColor
            ]
            []
        , div [ class "px-4 text-center" ]
            [ text settings.label
            ]
        , div
            [ class "h-px flex-grow"
            , class settings.lineColor
            ]
            []
        ]


inputRequired : Html msg
inputRequired =
    span [ class "ml-1 text-red-700" ]
        [ text "*"
        ]



--- Helpers


genericLink : Bool -> String -> String -> List (Attribute msg) -> Html msg
genericLink responsive icon label attrs =
    a
        attrs
        [ i
            [ class icon
            , classList
                [ ( "hidden", icon == "" )
                , ( "py-1 ", True )
                ]
            ]
            []
        , span
            [ class "ml-2"
            , classList
                [ ( "hidden", label == "" )
                , ( "hidden sm:inline", responsive && label /= "" )
                ]
            ]
            [ text label
            ]
        ]
