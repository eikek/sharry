module Pages.Login.View exposing (..)

import String
import Html exposing (Html, button, div, text, h2, form, i, input, img, a, span, br)
import Html.Attributes exposing (class, classList, type_, placeholder, src, href)
import Html.Events exposing (onClick, onInput, onSubmit)
import Pages.Login.Model exposing (Model)
import Pages.Login.Data exposing (..)

view: Model -> Html Msg
view model =
    div [ class "ui middle aligned center aligned grid" ]
        [
         div [ class "column login-page-column" ]
             [
              img [class "ui fluid image login-page-image" , src "static/sharry-webapp/logo.jpg"] []
              , h2 [ class "ui brown image header"]
                  [
                   div [class "content"]
                       [ text "Login, please" ]
                  ]
             , form [ onSubmit TryLogin, class "ui large form" ]
                 [
                   div [class "ui segment"]
                       [
                        div [ class "field" ]
                            [
                             div [class "ui left icon input"]
                                 [
                                  i [class "user icon"] []
                                 , input [type_ "text", placeholder "Login", onInput Login] []
                                 ]
                            ]
                       , div [ class "field" ]
                            [
                             div [class "ui left icon input"]
                                 [
                                  i [class "lock icon"] []
                                 , input [type_ "password", placeholder "Password", onInput Password] []
                                 ]
                            ]
                       , button [class "ui fluid large brown submit button"] [ text "Login" ]
                       ]
                 , div [classList
                            [ ("ui error message", True)
                            , ("visible", (String.length model.error > 0))
                            ]
                       ]
                       [ span [] [ text model.error ]
                       ]
                 ]
             , br [][]
             , a [href "https://github.com/eikek/sharry"]
                 [
                  i [class "github icon"] []
                 , text "Github"
                 ]
             ]
        ]
