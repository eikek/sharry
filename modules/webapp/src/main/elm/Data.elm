module Data exposing (..)

import Html exposing (Html)
import List
import Http
import Json.Decode as Decode exposing(field, at)
import Json.Encode as Encode
import Json.Decode.Pipeline as JP

-- Account type

type alias Account =
    { login: String
    , password: Maybe String
    , email: Maybe String
    , enabled: Bool
    , admin: Bool
    , extern: Bool
    }

emptyAccount: Account
emptyAccount =
    Account "" Nothing Nothing True False False

fromLogin: String -> Account
fromLogin login =
    {emptyAccount | login = login}

accountEncoder: Account -> Encode.Value
accountEncoder acc =
    Encode.object
    [ ("login", Encode.string acc.login)
    , ("password", Encode.string (Maybe.withDefault "" acc.password))
    , ("email", Encode.string (Maybe.withDefault "" acc.email))
    , ("enabled", Encode.bool acc.enabled)
    , ("admin", Encode.bool acc.admin)
    , ("extern", Encode.bool acc.extern)
    ]

accountDecoder: Decode.Decoder Account
accountDecoder =
    Decode.map6 Account
        (field "login" Decode.string)
        (field "password" (Decode.maybe Decode.string))
        (field "email" (Decode.maybe Decode.string))
        (field "enabled" Decode.bool)
        (field "admin" Decode.bool)
        (field "extern" Decode.bool)

-- Alias types

type alias Alias =
    {id: String
    ,login: String
    ,name: String
    ,validity: String
    ,created: String
    ,enable: Bool
    }

decodeAlias: Decode.Decoder Alias
decodeAlias =
    Decode.map6 Alias
        (field "id" Decode.string)
        (field "login" Decode.string)
        (field "name" Decode.string)
        (field "validity" Decode.string)
        (field "created" Decode.string)
        (field "enable" Decode.bool)

encodeAlias: Alias -> Encode.Value
encodeAlias alia =
    Encode.object
        [("id", Encode.string alia.id)
        ,("login", Encode.string alia.login)
        ,("name", Encode.string alia.name)
        ,("validity", Encode.string alia.validity)
        ,("created", Encode.string alia.created)
        ,("enable", Encode.bool alia.enable)
        ]

-- Upload types

{-| An upload can be identified by an public id (pid) and its standard id (uid).
-}
type UploadId
    = Uid String
    | Pid String

type alias File =
    {id: String
    ,timestamp: String
    ,mimetype: String
    ,length: Int
    ,chunks: Int
    ,chunksize: Int
    ,filename: String
    }

type alias Upload =
    {id: String
    ,login: String
    ,alia: Maybe String
    ,aliasName: Maybe String
    ,validity: String
    ,maxDownloads: Int
    ,requiresPassword: Bool
    ,validated: List String
    ,description: Maybe String
    ,created: String
    ,downloads: Int
    ,lastDownload: Maybe String
    ,publishId: Maybe String
    ,publishDate: Maybe String
    ,validUntil: Maybe String
    }

isValidUpload: Upload -> Bool
isValidUpload upload =
    List.isEmpty upload.validated

isPublishedUpload: Upload -> Bool
isPublishedUpload upload =
    isPresent upload.publishId


type alias UploadInfo =
    {upload: Upload
    ,files: List File
    }

decodeFile: Decode.Decoder File
decodeFile =
    Decode.map7 File
        (at ["meta","id"] Decode.string)
        (at ["meta","timestamp"] Decode.string)
        (at ["meta","mimetype"] Decode.string)
        (at ["meta","length"] Decode.int)
        (at ["meta","chunks"] Decode.int)
        (at ["meta","chunksize"] Decode.int)
        (at ["filename"] Decode.string)

decodeUpload: Decode.Decoder Upload
decodeUpload =
    JP.decode Upload
        |> JP.required "id" Decode.string
        |> JP.required "login" Decode.string
        |> JP.required "alias" (Decode.maybe Decode.string)
        |> JP.required "aliasName" (Decode.maybe Decode.string)
        |> JP.required "validity" Decode.string
        |> JP.required "maxDownloads" Decode.int
        |> JP.required "requiresPassword" Decode.bool
        |> JP.required "validated" (Decode.list Decode.string)
        |> JP.required "description" (Decode.maybe Decode.string)
        |> JP.required "created" Decode.string
        |> JP.required "downloads" Decode.int
        |> JP.required "lastDownload" (Decode.maybe Decode.string)
        |> JP.required "publishId" (Decode.maybe Decode.string)
        |> JP.required "publishDate" (Decode.maybe Decode.string)
        |> JP.required "validUntil" (Decode.maybe Decode.string)

decodeUploadInfo: Decode.Decoder UploadInfo
decodeUploadInfo =
    Decode.map2 UploadInfo
        (field "upload" decodeUpload)
        (field "files" (Decode.list decodeFile))



-- Outcome type
type alias Outcome a =
    { state: String
    , result: a
    }

outcomeDecoder: Decode.Decoder a -> Decode.Decoder (Outcome a)
outcomeDecoder adec =
    Decode.map2 Outcome
        (field "state" Decode.string)
        (field "result" adec)

-- Flag types

type alias RemoteUrls =
    {baseUrl: String
    ,authLogin: String
    ,authCookie: String
    ,logout: String
    ,accounts: String
    ,uploads: String
    ,uploadData: String
    ,uploadPublish: String
    ,download: String
    ,downloadZip: String
    ,downloadPublished: String
    ,downloadPublishedZip: String
    ,profileEmail: String
    ,profilePassword: String
    ,checkPassword: String
    ,aliases: String
    }

type alias RemoteConfig =
    { authEnabled: Bool
    , appName: String
    , cookieAge: Float
    , chunkSize: Int
    , simultaneousUploads: Int
    , maxFiles: Int
    , maxFileSize: Int
    , urls: RemoteUrls
    , projectName: String
    , aliasHeaderName: String
    }


-- utility stuff

httpPut: String -> Http.Body -> Decode.Decoder a -> (Http.Request a)
httpPut url body dec =
    Http.request
        { method = "PUT"
        , headers = []
        , url = url
        , body = body
        , expect = Http.expectJson dec
        , timeout = Nothing
        , withCredentials = False
        }

httpDelete: String -> Http.Body -> Decode.Decoder a -> (Http.Request a)
httpDelete url body dec =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = url
        , body = body
        , expect = Http.expectJson dec
        , timeout = Nothing
        , withCredentials = False
        }


errorMessage: Http.Error -> String
errorMessage err =
    case err of
        Http.Timeout ->
            "There was a network timeout!"
        Http.NetworkError ->
            "There was a network error!"
        Http.BadStatus resp ->
            (decodeError resp)
        Http.BadPayload msg resp ->
            msg ++ "; Response: " ++ (decodeError resp)
        Http.BadUrl msg ->
            "Internal error: invalid url for request."


decodeError: Http.Response String -> String
decodeError resp =
    let
        msg =
            Decode.decodeString (field "message" Decode.string) resp.body
        text =
            case msg of
                Ok msg -> msg
                _ -> resp.body
    in
        if ((String.length text) > 0) then text
        else "Some error occured at the server without giving specific error message: " ++ (toString resp.status)



nonEmpty: List a -> Bool
nonEmpty list =
    not (List.isEmpty list)


type SizeUnit = G|M|K|B

prettyNumber: Float -> String
prettyNumber n =
    let
        parts = String.split "." (toString n)
    in
        case parts of
            n :: d :: [] -> n ++ "." ++ (String.left 2 d)
            _ -> String.join "." parts

bytesReadable: SizeUnit -> Float -> String
bytesReadable unit n =
    let
        k = n / 1024
        num = prettyNumber n
    in
    case unit of
        G -> num ++ "G"
        M -> if k > 1 then (bytesReadable G k) else num ++ "M"
        K -> if k > 1 then (bytesReadable M k) else num ++ "K"
        B -> if k > 1 then (bytesReadable K k) else num ++ "B"

defer: Cmd m -> (a,b) -> (a, b, Cmd m)
defer c (a,b) =
    (a, b, c)

htmlList: List (Bool, Html msg) -> List (Html msg)
htmlList tupleList =
    List.filterMap (\(a, b) -> if a then Just b else Nothing) tupleList


maybeOrElse: Maybe a -> Maybe a -> Maybe a
maybeOrElse a b =
    case a of
        Just _ -> a
        Nothing -> b

nonEmptyStr: String -> Maybe String
nonEmptyStr str =
    if str == "" then Nothing else Just str

parseMime: String -> (String, String)
parseMime mime =
    let
        unknown = ("application", "octet-stream")
    in
    case String.split ";" mime of
        x :: [] ->
            case String.split "/" x of
                media :: sub :: [] ->
                    (media, sub)
                _ -> unknown
        _ -> unknown

isPresent: Maybe a -> Bool
isPresent mb =
    Maybe.map (\_ -> True) mb
        |> Maybe.withDefault False

parseDuration: String -> Maybe (Int, String)
parseDuration str =
    let
        lower = String.toLower str
    in
        if String.startsWith "pt" lower then
            case String.toInt (String.dropLeft 2 lower |> String.dropRight 1) of
                Ok n ->
                    (n, String.right 1 lower) |> Just
                _ ->
                    Nothing
        else
            Nothing

formatDuration: String -> String
formatDuration str =
    case parseDuration str of
        Just (n, "h") ->
            if rem n 24 == 0 then
                (toString (n // 24)) ++ "d"
            else
                (toString n) ++ "h"
        Just (n, unit) ->
            (toString n) ++ unit
        Nothing ->
            str
