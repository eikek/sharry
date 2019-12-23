module Page.Upload.Update exposing (update)

import Api
import Browser.Navigation as Nav
import Comp.ShareTable
import Data.Flags exposing (Flags)
import Page exposing (Page(..))
import Page.Upload.Data exposing (Model, Msg(..))


update : Nav.Key -> Flags -> Msg -> Model -> ( Model, Cmd Msg )
update key flags msg model =
    case msg of
        Init ->
            ( model, Api.findShares flags model.query SearchResp )

        SetQuery str ->
            ( { model | query = str }
            , Api.findShares flags str SearchResp
            )

        ShareTableMsg lmsg ->
            let
                ( lm, selected ) =
                    Comp.ShareTable.update lmsg model.tableModel

                cmd =
                    case selected of
                        Just id ->
                            Page.set key (DetailPage id.id)

                        Nothing ->
                            Cmd.none
            in
            ( { model | tableModel = lm, selected = selected }
            , cmd
            )

        SearchResp (Ok list) ->
            ( { model | searchResult = list.items }
            , Cmd.none
            )

        SearchResp (Err err) ->
            ( model, Cmd.none )
