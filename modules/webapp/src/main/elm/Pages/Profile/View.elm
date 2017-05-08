module Pages.Profile.View exposing (..)

import Html exposing (Html, div, h1, text, i)
import Html.Attributes exposing (class)

import Pages.Profile.Model exposing (..)
import Widgets.UpdateEmailForm as UpdateEmailForm
import Widgets.UpdatePasswordForm as UpdatePasswordForm

view: Model -> Html Msg
view model =
    div []
        [
         div [class "main ui grid container"]
             [
              div [class "sixteen wide column"]
                  [
                   h1 [class "ui header"]
                       [
                        i [class "user icon"][]
                       ,text (model.name ++ "'s Profile")
                       ]
                  ]
             ,div [class "sixteen wide column"]
                  [
                   (Html.map UpdateEmailFormMsg (UpdateEmailForm.view model.updateEmail))
                  ]
             ,div [class "sixteen wide column"]
                 [
                  (Html.map UpdatePasswordFormMsg (UpdatePasswordForm.view model.updatePassword))
                 ]
             ]
        ]
