module Pages.AccountEdit.View exposing (..)

import List
import Html exposing (Html, div, text, span, i, input, a, p, h2)
import Html.Attributes exposing (class, classList)
import Html.Events exposing (onClick)

import Data exposing (Account)

import Widgets.AccountForm as AccountForm
import Widgets.LoginSearch as LoginSearch

import Pages.AccountEdit.Model exposing (..)
import Pages.AccountEdit.Update exposing (..)

view: Model -> Html Msg
view model =
    let
        accForm =
            case model.accountForm of
                Just acc -> Html.map AccountFormMsg (AccountForm.view acc)
                Nothing -> div[][]
    in
        div [class "main ui grid container"]
            [
             div [class "ui two column centered row"]
                 [
                  div [class "column"]
                      (viewSearchAndButton model)
                 ]
            ,div [class "row"]
                [
                 div [class "ten wide column"]
                     [accForm]
                ,div [class "six wide column"]
                    (infoMessage model)
                ]
            ]

infoMessage: Model -> List (Html a)
infoMessage model =
    case model.accountForm of
        Just account ->
            [
             h2 [class "ui horizontal divider header"]
                 [
                  text (toString account.update)
                 ]
            , (infoText account)
            ]
        Nothing ->
            []

infoText: AccountForm.Model  -> Html a
infoText model =
    case model.update of
        AccountForm.Modify ->
            modifyHint
        AccountForm.Create ->
            createHint

modifyHint: Html a
modifyHint =
    Data.markdownHtml """
This will update the account as follows:

* leave `password` empty to not change it
* `Email` is optional, used to send a new passwords and notifications on received files
"""

createHint: Html a
createHint =
    Data.markdownHtml """
Create a new account:

* supply `Password` for internal accounts
* do not set `Password` for external accounts
* login names must be alphanumeric and start with a letter
* `Email` is optional, used to send a new passwords and notifications on received files
"""

viewSearchAndButton: Model -> List (Html Msg)
viewSearchAndButton model =
    [
     div [class "ui raised brown segment"]
         [
          (Html.map LoginSearchMsg (LoginSearch.view model.search))
         ,div [class "ui horizontal divider"][text "Or"]
         ,a [class "ui brown labeled icon button", onClick NewAccount]
             [
              text "Create New Account"
             ,i [class "add icon"][]
             ]
         ,div [classList
                   [ ("row ui error message", True)
                   , ("hidden", model.errorMsg == "")
                   , ("visible", (String.length model.errorMsg > 0))
                   ]
              ]
              [ span [] [ text model.errorMsg ]
              ]
         ]
    ]
