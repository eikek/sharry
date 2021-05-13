module Comp.MailSend exposing
    ( Action(..)
    , Model
    , Msg
    , emptyModel
    , init
    , update
    , view
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.MailTemplate exposing (MailTemplate)
import Comp.Basic as B
import Comp.MailForm exposing (FormAction(..))
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Messages.MailSend exposing (Texts)
import Styles as S
import Util.Http


type alias Model =
    { mailForm : Comp.MailForm.Model
    , result : Maybe BasicResult
    , loader : Loader
    }


type alias Loader =
    { active : Bool
    , message : Texts -> String
    }


sendingLoader : Loader
sendingLoader =
    { active = True
    , message = \texts -> texts.sendingEmail
    }


templateLoader : Loader
templateLoader =
    { active = True
    , message = \texts -> texts.loadingTemplate
    }


noLoader : Loader
noLoader =
    { active = False
    , message = \_ -> ""
    }


emptyModel : Model
emptyModel =
    { mailForm = Comp.MailForm.init
    , result = Nothing
    , loader = noLoader
    }


init :
    ((Result Http.Error MailTemplate -> Msg)
     -> Cmd Msg
    )
    -> ( Model, Cmd Msg )
init getTpl =
    ( { emptyModel | loader = templateLoader }, getTpl MailTplResp )


type Msg
    = MailFormMsg Comp.MailForm.Msg
    | MailTplResp (Result Http.Error MailTemplate)
    | MailSendResp (Result Http.Error BasicResult)


type Action
    = Run (Cmd Msg)
    | Cancelled
    | Sent


update : Flags -> Msg -> Model -> ( Model, Action )
update flags msg model =
    case msg of
        MailFormMsg lmsg ->
            let
                ( mm, act ) =
                    Comp.MailForm.update lmsg model.mailForm
            in
            case act of
                Comp.MailForm.FormNone ->
                    ( { model | mailForm = mm }, Run Cmd.none )

                Comp.MailForm.FormCancel ->
                    ( { model | result = Nothing }
                    , Cancelled
                    )

                Comp.MailForm.FormSend mail ->
                    ( { model | mailForm = mm, loader = sendingLoader }
                    , Run (Api.sendMail flags mail MailSendResp)
                    )

        MailTplResp (Ok templ) ->
            ( { model | mailForm = Comp.MailForm.initWith templ, loader = noLoader }
            , Run Cmd.none
            )

        MailTplResp (Err err) ->
            ( { model
                | result = Just (BasicResult False (Util.Http.errorToString err))
                , loader = noLoader
              }
            , Run Cmd.none
            )

        MailSendResp (Ok br) ->
            ( { model
                | result =
                    if br.success then
                        Nothing

                    else
                        Just br
                , loader = noLoader
              }
            , if br.success then
                Sent

              else
                Run Cmd.none
            )

        MailSendResp (Err err) ->
            ( { model
                | result = Just (BasicResult False (Util.Http.errorToString err))
                , loader = noLoader
              }
            , Run Cmd.none
            )


view : Texts -> List ( String, Bool ) -> Model -> Html Msg
view texts classes model =
    div
        [ classList classes
        , class "relative"
        ]
        [ B.loadingDimmer
            { active = model.loader.active
            , label = model.loader.message texts
            }
        , div
            [ classList
                [ ( "hidden", model.result == Nothing )
                , ( S.errorMessage
                  , Maybe.map .success model.result
                        |> Maybe.map not
                        |> Maybe.withDefault False
                  )
                ]
            ]
            [ Maybe.map .message model.result
                |> Maybe.withDefault ""
                |> text
            ]
        , Html.map MailFormMsg
            (Comp.MailForm.view
                texts.mailForm
                model.mailForm
            )
        ]
