module Widgets.DownloadView exposing (..)

import Http
import Html exposing (Html, div, text, h2, h3)
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as Decode exposing (field, at)
import Json.Encode as Encode
import Data exposing (Account, UploadInfo, File, RemoteUrls, RemoteConfig, UploadId(..), htmlList)
import PageLocation as PL
import Widgets.MailForm as MailForm

type alias Model =
    {info: UploadInfo
    ,cfg: RemoteConfig
    ,login: Maybe String
    ,password: Maybe String
    ,validPassword: Bool
    ,errorMessage: List String
    ,mailForm: Maybe MailForm.Model
    }

type Msg
    = SetPassword String
    | PasswordAttempt
    | PasswordCheck (Result Http.Error (List String))
    | DeleteDownload
    | DeleteDownloadResult (Result Http.Error Int)
    | PublishDownload
    | UnpublishDownload
    | PublishDownloadResult (Result Http.Error UploadInfo)
    | OpenMailForm
    | MailFormCancel
    | MailFormMsg MailForm.Msg

makeModel: UploadInfo -> RemoteConfig -> Maybe Account -> Model
makeModel info cfg account =
    Model info cfg (Maybe.map (\a -> a.login) account) Nothing False [] Nothing


isOwner: Model -> Bool
isOwner model =
    Maybe.map (\s -> s == model.info.upload.login) model.login
        |> Maybe.withDefault False

isAskPassword: Model -> Bool
isAskPassword model =
    model.info.upload.requiresPassword && (not model.validPassword)

isValid: Model -> Bool
isValid model =
    Data.isValidUpload model.info.upload

hasPasswordErrors: Model -> Bool
hasPasswordErrors model =
    not (List.isEmpty model.errorMessage)

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        SetPassword p ->
            {model | password = Just p, errorMessage = []} ! []

        PasswordAttempt ->
            model ! [httpCheckPassword model]

        PasswordCheck (Ok list) ->
            {model| validPassword = List.isEmpty list, errorMessage = list} ! []
            
        PasswordCheck (Err error) ->
            {model | errorMessage =  [Data.errorMessage error]} ! [PL.timeoutCmd error]

        DeleteDownload ->
            model ! [httpDeleteDownload model]

        DeleteDownloadResult (Ok n) ->
            model ! [PL.uploadsPage]

        DeleteDownloadResult (Err error) ->
            {model | errorMessage = Debug.log "Error deleting download" [(Data.errorMessage error)]} ! [PL.timeoutCmd error]

        PublishDownload ->
            model ! [httpPublishDownload model]

        PublishDownloadResult (Ok info) ->
            {model | info = info} ! []

        PublishDownloadResult (Err error) ->
            {model | errorMessage = Debug.log "Error un-/publishing download" [(Data.errorMessage error)]} ! [PL.timeoutCmd error]

        UnpublishDownload ->
            model ! [httpUnpublishDownload model]

        OpenMailForm ->
            {model | mailForm = Just (MailForm.makeModel model.cfg.urls)} ! [httpGetTemplate model]

        MailFormCancel ->
            {model | mailForm = Nothing} ! []

        MailFormMsg msg ->
            case model.mailForm of
                Just m ->
                    let
                        (m_, c) = MailForm.update msg m
                    in
                        {model | mailForm = Just m_} ! [Cmd.map MailFormMsg c]
                Nothing ->
                    model ! []


view: Model -> List (Html Msg)
view model =
    case model.mailForm of
        Just m ->
            viewMailForm m
        Nothing ->
            viewPage model

viewMailForm: MailForm.Model -> List (Html Msg)
viewMailForm model =
    [div [HA.class "sixteen wide column"]
         [
          Html.a [HA.class "ui button", HE.onClick MailFormCancel][text "Back"]
         ,div [HA.class "ui divider"][]
         ]
    ,div [HA.class "sixteen wide column"]
        [h2 [HA.class "ui header"][text "Send an email"]
        ,(Html.map MailFormMsg (MailForm.view model))
        ]
    ]
                
viewPage: Model -> List (Html Msg)
viewPage model =
    let
        msg = Maybe.withDefault (defaultDescription model) model.info.upload.description
    in
        htmlList [
             (not (isValid model || isOwner model),
                  renderDimmer model)
            ,(not (isOwner model) && isValid model && isAskPassword model,
                  passwordForm model)
            ,(True, div [HA.class "sixteen wide column"]
                  [(Data.markdownHtml msg)])
            ,(True, div [HA.class "eight wide column"]
                  (uploadInfoItems model))
            ,(True, div [HA.class "six wide column"]
                  (downloadInfoItems model))
            ,(True, div [HA.class "two wide column"]
                  [actionButtons model])
            ,(isValid model && isOwner model, infoMessage model)
            ,(model.info.upload.requiresPassword && isOwner model,
                  div [HA.class "sixteen wide column"]
                      (passwordHint model))
            ,(not (isValid model) && isOwner model,
                  div [HA.class "sixteen wide column"]
                      (validatedHint model))
            ,(True, div [HA.class "sixteen wide column"]
                  [
                   h2 [HA.class "ui header"][
                        text "Files"
                       ,div [HA.class "sub header"]
                            [text (fileSummary model)]
                       ]
                  ,div [HA.class "ui relaxed divided list"]
                      (if List.isEmpty model.info.files then
                          [text "No files attached."]
                      else
                          (List.map (renderFile model) model.info.files))
                  ])
            ]

infoMessage: Model -> Html msg
infoMessage model =
    case model.info.upload.publishId of
        Just id ->
            let
                href = PL.downloadPageHref (Pid id)
                url = model.cfg.urls.baseUrl ++ href
            in
                div []
                    [text "You can share this page with others by sending the following link:"
                    ,Html.br[][]
                    ,Html.a[HA.href href][text url]
                    ]
        Nothing ->
            div[][]
            

defaultDescription: Model -> String
defaultDescription model =
    if (isOwner model) then "# Your Upload"
    else
        """# Your Files

Someone provided the following files. Download is available for the given time period."""

        
uploadInfoItems: Model -> List (Html msg)
uploadInfoItems model =
    [
     div [HA.class "ui list"]
         [
          div [HA.class "item"]
              [Html.i [HA.class "calendar outline icon"][]
              ,div [HA.class "content"]
                  [
                   div [HA.class "header"]
                       [text "Uploaded at"]
                  ,div [HA.class "content"]
                      [text (Data.formatDate model.info.upload.created)]
                  ]
              ]
              
         ,div [HA.class "item"]
             [Html.i [HA.class "hashtag icon"][]
             ,div [HA.class "content"]
                 [
                  div [HA.class "header"]
                      [text "Publish Id"]
                 ,div [HA.class "content"]
                     [case model.info.upload.publishId of
                          Just id ->
                              Html.a[HA.href (PL.downloadPageHref (Pid id))][text id]
                          Nothing ->
                              text "-"
                     ]
                 ]
             ]
             
         ,div [HA.class "item"]
             [Html.i [HA.class "calendar icon"][]
             ,div [HA.class "content"]
                 [
                  div [HA.class "header"]
                      [text "Published on"]
                 ,div [HA.class "content"]
                     [Maybe.map Data.formatDate model.info.upload.publishDate |> Maybe.withDefault "-" |> text]
                 ]
             ]
             
         ,div [HA.class "item"]
             [Html.i [HA.class "download icon"][]
             ,div [HA.class "content"]
                 [
                  div [HA.class "header"]
                      [text "Max. downloads"]
                 ,div [HA.class "content"]
                     [toString model.info.upload.maxDownloads |> text]
                 ]
             ]                     
         ]
    ]
    
downloadInfoItems: Model -> List (Html msg)
downloadInfoItems model =
    [
     div [HA.class "ui list"]
         [
          div [HA.class "item"]
              [Html.i [HA.class "download icon"][]
              ,div [HA.class "content"]
                  [
                   div [HA.class "header"]
                       [text "Downloads"]
                  ,div [HA.class "content"]
                      [toString model.info.upload.downloads |> text]
                  ]
              ]
                  
         ,div [HA.class "item"]
             [Html.i [HA.class "download icon"][]
             ,div [HA.class "content"]
                 [
                  div [HA.class "header"]
                      [text "Last download at"]
                 ,div [HA.class "content"]
                     [Maybe.map Data.formatDate model.info.upload.lastDownload |> Maybe.withDefault "-" |> text]
                 ]
             ]
             
         ,div [HA.class "item"]
             [Html.i [HA.class "protect icon"][]
             ,div [HA.class "content"]
                 [
                  div [HA.class "header"]
                      [text "Valid until"]
                 ,div [HA.class "content"]
                     [Maybe.map Data.formatDate model.info.upload.validUntil |> Maybe.withDefault "-" |> text]
                 ]
             ]
         ]
    ]
    
passwordHint: Model -> List (Html msg)
passwordHint model =
    if (model.info.upload.requiresPassword && isOwner model) then
        div [HA.class "eight wide column"]
        [
         div [HA.class "ui info message"]
             [
              div []
                  [text "This download requires a password!"]
             ]
        ] |> List.singleton
    else
        []

validatedHint: Model -> List (Html msg)
validatedHint model =
    if isValid model && not (isOwner model) then []
    else div [HA.class "eight wide column"]
        [
         div [HA.class "ui info message"]
             [
              div [HA.class "header"]
                  [text "This is not a valid public download!"]
             ,Html.ul [HA.class "list"]
                 (List.map (\s -> Html.li[][text s]) model.info.upload.validated)
             ]
        ] |> List.singleton
    
renderDimmer: Model -> Html msg
renderDimmer model =
    div [HA.class "ui active dimmer"]
        [
         div [HA.class "content"]
             [
              div [HA.class "center"]
                  [
                   h2 [HA.class "ui inverted icon header"]
                       [
                        Html.i [HA.class "meh icon"][]
                       ,text "This download is not available anymore!"
                       ]
                  ,div []
                      (List.map (\s -> Html.p[][text s]) model.info.upload.validated)
                  ]
             ]
        ]
        
renderFile: Model -> File -> Html msg
renderFile model file =
    let
        downloadUrl = if isOwner model then
                          model.cfg.urls.download ++ "/" ++ file.id
                      else if isValid model && not (isAskPassword model) then
                          model.cfg.urls.downloadPublished ++ "/" ++ file.id
                      else
                          "#"
        mimecss = case Data.parseMime file.mimetype of
                      ("application", "zip") -> "file archive outline"
                      ("application", "pdf") -> "file pdf outline"
                      ("text", _) -> "file text outline"
                      ("image", _) -> "file image outline"
                      ("audio", _) -> "file audio outline"
                      ("video", _) -> "file video outline"
                      ("application", "vnd.openxmlformats-officedocument.wordprocessingml.document") ->
                          "file word outline"
                      ("application", "vnd.openxmlformats-officedocument.spreadsheetml.sheet") ->
                          "file excel outline"
                      ("application", "vnd.openxmlformats-officedocument.presentationml.presentation") ->
                          "file powerpoint outline"
                      _ -> "file outline"
    in
        div [HA.class "item"]
            [Html.i [HA.class ("large " ++ mimecss ++ " middle aligned icon")][]
            ,div [HA.class "content"]
                [
                 Html.a [HA.class "header", HA.href downloadUrl]
                     [text file.filename]
                ,div [HA.class "content"]
                    [Data.bytesReadable Data.B (toFloat file.length) |> text]
                ]
        ]

passwordForm: Model -> Html Msg
passwordForm model =
    div [HA.class "ui active dimmer"]
        [
         div [HA.class "content"]
             [
              div [HA.class "ui center aligned grid"]
                  [
                   div [HA.class "sixteen wide column"]
                       [
                        h2 [HA.class "ui inverted icon header"]
                            [
                             Html.i [HA.class "lock icon"][]
                            ,text "This download requires a password."
                            ]
                       ]
                  ,div [HA.class "eight wide column"]
                      [
                       Html.form [HE.onSubmit PasswordAttempt, HA.classList [("error", hasPasswordErrors model)]]
                           [
                            div [HA.class "ui right action left icon input"]
                                [
                                 Html.i [HA.class "lock icon"] []
                                ,Html.input [HA.type_ "password", HA.placeholder "Password", HA.size 30, HE.onInput SetPassword] []
                                ,Html.button [HA.class "ui basic floating brown submit button"] [ text "Submit" ]
                                ]
                           ,case model.errorMessage of
                                [] ->
                                    div [HA.class "ui basic segment"][text ""]
                                a :: [] ->
                                    div [HA.class "ui basic red segment"][text a]
                                _ ->
                                    div [HA.class "ui basic red segment"]
                                        [Html.ul []
                                             (List.map (\t -> Html.li[][text t]) model.errorMessage)
                                        ]
                           ]
                      ]
                 ]

             ]
        ]
    

actionButtons: Model -> Html Msg
actionButtons model =
    div [HA.class "ui vertical buttons"]
        <| Data.htmlList
            [(isOwner model && not (Data.isPublishedUpload model.info.upload),
                  Html.button [HA.class "ui button", HE.onClick PublishDownload][text "Publish"])
            ,(isOwner model && Data.isPublishedUpload model.info.upload,
                  Html.button [HA.class "ui button", HE.onClick UnpublishDownload][text "Unpublish"])
            ,(isOwner model,
                  Html.button [HA.class "negative ui button", HE.onClick DeleteDownload][text "Delete"])
            ,(List.length model.info.files > 1,
                  zipDownloadButton model)
            ,(isOwner model && isValid model && model.cfg.mailEnabled,
                  Html.button [HA.class "ui button", HE.onClick OpenMailForm][text "Send email"])
            ]

zipDownloadButton: Model -> Html msg
zipDownloadButton model =
    let
        url = if isOwner model then
                  model.cfg.urls.downloadZip ++ "/" ++ model.info.upload.id
              else if isValid model then
                  model.cfg.urls.downloadPublishedZip ++ "/" ++ (Maybe.withDefault "" model.info.upload.publishId)
              else
                  "#"
    in
        Html.a [HA.class "ui button", HA.href url]
            [text "Download as Zip"]

fileSummary: Model -> String
fileSummary model =
    if (List.length model.info.files) > 1 then
        (toString (List.length model.info.files)) ++ ", " ++ (sumFileSize model)
    else
        ""
             
sumFileSize: Model -> String
sumFileSize model =
    model.info.files
        |> List.map .length
        |> List.sum
        |> toFloat
        |> Data.bytesReadable Data.B

httpCheckPassword: Model -> Cmd Msg
httpCheckPassword model =
    let
        url id = model.cfg.urls.checkPassword ++ "/" ++ id
        decoder =  Decode.list Decode.string
        encoded pass =  Encode.object [("password", Encode.string pass)]
        makeCmd pass id =
            Http.post (url id) (Http.jsonBody (encoded pass)) decoder
                |> Http.send PasswordCheck
    in
        Maybe.map2 makeCmd model.password model.info.upload.publishId
            |> Maybe.withDefault Cmd.none

httpDeleteDownload: Model -> Cmd Msg
httpDeleteDownload model =
    Data.httpDelete (model.cfg.urls.uploads ++ "/" ++ model.info.upload.id) Http.emptyBody (Decode.field "filesRemoved" Decode.int)
        |> Http.send DeleteDownloadResult
               

httpPublishDownload: Model -> Cmd Msg
httpPublishDownload model =
    Http.post (model.cfg.urls.uploadPublish ++ "/" ++ model.info.upload.id) Http.emptyBody Data.decodeUploadInfo
        |> Http.send PublishDownloadResult

httpUnpublishDownload: Model -> Cmd Msg
httpUnpublishDownload model =
    Http.post (model.cfg.urls.uploadUnpublish ++ "/" ++ model.info.upload.id) Http.emptyBody Data.decodeUploadInfo
        |> Http.send PublishDownloadResult

httpGetTemplate: Model -> Cmd Msg
httpGetTemplate model =
    case model.info.upload.publishId of
        Just id ->
            let
                href = PL.downloadPageHref (Pid id) 
                url = model.cfg.urls.baseUrl ++ href
                templateUrl = model.cfg.urls.mailDownloadTemplate 
                              ++ "?url=" ++ (Http.encodeUri url)
                              ++ "&pass="++ (toString model.info.upload.requiresPassword)
                cmd = Http.get templateUrl MailForm.decodeTemplate
                          |> Http.send MailForm.TemplateResult
            in
                Cmd.map MailFormMsg cmd
        Nothing ->
            Cmd.none
