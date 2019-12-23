module Page.Settings.Data exposing
    ( Banner
    , Model
    , Msg(..)
    , emptyModel
    )

import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.EmailInfo exposing (EmailInfo)
import Comp.PasswordInput
import Http


type alias Banner =
    { success : Bool
    , text : String
    }


type alias Model =
    { oldPasswordModel : Comp.PasswordInput.Model
    , oldPasswordField : Maybe String
    , newPasswordModel1 : Comp.PasswordInput.Model
    , newPasswordField1 : Maybe String
    , newPasswordModel2 : Comp.PasswordInput.Model
    , newPasswordField2 : Maybe String
    , emailField : Maybe String
    , currentEmail : Maybe String
    , banner : Maybe Banner
    }


emptyModel : Model
emptyModel =
    { oldPasswordModel = Comp.PasswordInput.init
    , oldPasswordField = Nothing
    , newPasswordModel1 = Comp.PasswordInput.init
    , newPasswordField1 = Nothing
    , newPasswordModel2 = Comp.PasswordInput.init
    , newPasswordField2 = Nothing
    , emailField = Nothing
    , currentEmail = Nothing
    , banner = Nothing
    }


type Msg
    = Init
    | SetEmail String
    | SubmitEmail
    | SetOldPassword Comp.PasswordInput.Msg
    | SetNewPassword1 Comp.PasswordInput.Msg
    | SetNewPassword2 Comp.PasswordInput.Msg
    | SubmitPassword
    | GetEmailResp (Result Http.Error EmailInfo)
    | SaveResp (Result Http.Error BasicResult)
