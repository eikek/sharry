module Pages.Profile.Update exposing (..)

import Pages.Profile.Model exposing (..)
import Widgets.UpdateEmailForm as UpdateEmailForm
import Widgets.UpdatePasswordForm as UpdatePasswordForm

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        UpdateEmailFormMsg msg ->
            let
                (m, c) = UpdateEmailForm.update msg model.updateEmail
            in
                {model | updateEmail = m} ! [Cmd.map UpdateEmailFormMsg c]

        UpdatePasswordFormMsg msg ->
            let
                (m, c) = UpdatePasswordForm.update msg model.updatePassword
            in
                {model | updatePassword = m} ! [Cmd.map UpdatePasswordFormMsg c]
