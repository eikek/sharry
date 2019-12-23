module Api exposing
    ( changePassword
    , createAccount
    , createAlias
    , createEmptyShare
    , createEmptyShareAlias
    , deleteAlias
    , deleteFile
    , deleteShare
    , fileOpenUrl
    , fileSecUrl
    , findShares
    , getAlias
    , getAliasTemplate
    , getEmail
    , getOpenShare
    , getShare
    , getShareTemplate
    , listAccounts
    , listAlias
    , loadAccount
    , login
    , loginSession
    , logout
    , modifyAccount
    , modifyAlias
    , newInvite
    , notifyAliasUpload
    , oauthUrl
    , publishShare
    , refreshSession
    , register
    , sendMail
    , setDescription
    , setEmail
    , setMaxViews
    , setName
    , setPassword
    , setValidity
    , unpublishShare
    , versionInfo
    )

import Api.Model.AccountCreate exposing (AccountCreate)
import Api.Model.AccountDetail exposing (AccountDetail)
import Api.Model.AccountList exposing (AccountList)
import Api.Model.AccountModify exposing (AccountModify)
import Api.Model.AliasChange exposing (AliasChange)
import Api.Model.AliasDetail exposing (AliasDetail)
import Api.Model.AliasList exposing (AliasList)
import Api.Model.AuthResult exposing (AuthResult)
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.EmailChange exposing (EmailChange)
import Api.Model.EmailInfo exposing (EmailInfo)
import Api.Model.GenInvite exposing (GenInvite)
import Api.Model.IdResult exposing (IdResult)
import Api.Model.InviteResult exposing (InviteResult)
import Api.Model.MailTemplate exposing (MailTemplate)
import Api.Model.OAuthItem exposing (OAuthItem)
import Api.Model.PasswordChange exposing (PasswordChange)
import Api.Model.PublishData exposing (PublishData)
import Api.Model.Registration exposing (Registration)
import Api.Model.ShareDetail exposing (ShareDetail)
import Api.Model.ShareList exposing (ShareList)
import Api.Model.ShareProperties exposing (ShareProperties)
import Api.Model.SimpleMail exposing (SimpleMail)
import Api.Model.SingleNumber exposing (SingleNumber)
import Api.Model.SingleString exposing (SingleString)
import Api.Model.UserPass exposing (UserPass)
import Api.Model.VersionInfo exposing (VersionInfo)
import Data.Flags exposing (Flags)
import Http
import Task
import Url
import Util.Http as Http2


getAliasTemplate :
    Flags
    -> String
    -> (Result Http.Error MailTemplate -> msg)
    -> Cmd msg
getAliasTemplate flags aliasId receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v2/sec/mail/template/alias/" ++ aliasId
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.MailTemplate.decoder
        }


getShareTemplate :
    Flags
    -> String
    -> (Result Http.Error MailTemplate -> msg)
    -> Cmd msg
getShareTemplate flags shareId receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v2/sec/mail/template/share/" ++ shareId
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.MailTemplate.decoder
        }


sendMail :
    Flags
    -> SimpleMail
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
sendMail flags mail receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v2/sec/mail/send"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.SimpleMail.encode mail)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


notifyAliasUpload :
    Flags
    -> String
    -> String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
notifyAliasUpload flags aliasId shareId receive =
    Http2.aliasPost
        { url = flags.config.baseUrl ++ "/api/v2/alias/mail/notify/" ++ shareId
        , aliasId = aliasId
        , body = Http.emptyBody
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


fileSecUrl : Flags -> String -> String -> String
fileSecUrl flags share fid =
    flags.config.baseUrl ++ "/api/v2/sec/share/" ++ share ++ "/file/" ++ fid


fileOpenUrl : Flags -> String -> String -> String
fileOpenUrl flags share fid =
    flags.config.baseUrl ++ "/api/v2/open/share/" ++ share ++ "/file/" ++ fid


setPassword :
    Flags
    -> String
    -> Maybe String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
setPassword flags id value receive =
    case value of
        Just name ->
            Http2.authPost
                { url = flags.config.baseUrl ++ "/api/v2/sec/share/" ++ id ++ "/password"
                , account = getAccount flags
                , body = Http.jsonBody (Api.Model.SingleString.encode (SingleString name))
                , expect = Http.expectJson receive Api.Model.BasicResult.decoder
                }

        Nothing ->
            Http2.authDelete
                { url = flags.config.baseUrl ++ "/api/v2/sec/share/" ++ id ++ "/password"
                , account = getAccount flags
                , expect = Http.expectJson receive Api.Model.BasicResult.decoder
                }


setMaxViews :
    Flags
    -> String
    -> Int
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
setMaxViews flags id value receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v2/sec/share/" ++ id ++ "/maxviews"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.SingleNumber.encode (SingleNumber value))
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setValidity :
    Flags
    -> String
    -> Int
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
setValidity flags id value receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v2/sec/share/" ++ id ++ "/validity"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.SingleNumber.encode (SingleNumber value))
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


setName :
    Flags
    -> String
    -> Maybe String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
setName flags id value receive =
    case value of
        Just name ->
            Http2.authPost
                { url = flags.config.baseUrl ++ "/api/v2/sec/share/" ++ id ++ "/name"
                , account = getAccount flags
                , body = Http.jsonBody (Api.Model.SingleString.encode (SingleString name))
                , expect = Http.expectJson receive Api.Model.BasicResult.decoder
                }

        Nothing ->
            Http2.authDelete
                { url = flags.config.baseUrl ++ "/api/v2/sec/share/" ++ id ++ "/name"
                , account = getAccount flags
                , expect = Http.expectJson receive Api.Model.BasicResult.decoder
                }


setDescription :
    Flags
    -> String
    -> String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
setDescription flags id value receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v2/sec/share/" ++ id ++ "/description"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.SingleString.encode (SingleString value))
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


deleteShare : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
deleteShare flags id receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v2/sec/share/" ++ id
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


deleteFile :
    Flags
    -> String
    -> String
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
deleteFile flags share file receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v2/sec/share/" ++ share ++ "/file/" ++ file
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


publishShare : Flags -> String -> PublishData -> (Result Http.Error BasicResult -> msg) -> Cmd msg
publishShare flags id pd receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v2/sec/share/" ++ id ++ "/publish"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.PublishData.encode pd)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


unpublishShare : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
unpublishShare flags id receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v2/sec/share/" ++ id ++ "/publish"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


getShare : Flags -> String -> (Result Http.Error ShareDetail -> msg) -> Cmd msg
getShare flags id receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v2/sec/share/" ++ id
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.ShareDetail.decoder
        }


getOpenShare : Flags -> String -> Maybe String -> (Result Http.Error ShareDetail -> msg) -> Cmd msg
getOpenShare flags id pass receive =
    Http2.getH
        { url = flags.config.baseUrl ++ "/api/v2/open/share/" ++ id
        , headers =
            case pass of
                Just pw ->
                    [ Http.header "Sharry-Password" pw ]

                Nothing ->
                    []
        , expect = Http.expectJson receive Api.Model.ShareDetail.decoder
        }


findShares : Flags -> String -> (Result Http.Error ShareList -> msg) -> Cmd msg
findShares flags query receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v2/sec/share/search?q=" ++ Url.percentEncode query
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.ShareList.decoder
        }


createEmptyShareAlias :
    Flags
    -> String
    -> ShareProperties
    -> (Result Http.Error IdResult -> msg)
    -> Cmd msg
createEmptyShareAlias flags aliasId props receive =
    Http2.aliasPost
        { url = flags.config.baseUrl ++ "/api/v2/alias/upload/new"
        , aliasId = aliasId
        , body = Http.jsonBody (Api.Model.ShareProperties.encode props)
        , expect = Http.expectJson receive Api.Model.IdResult.decoder
        }


createEmptyShare : Flags -> ShareProperties -> (Result Http.Error IdResult -> msg) -> Cmd msg
createEmptyShare flags props receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v2/sec/upload/new"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.ShareProperties.encode props)
        , expect = Http.expectJson receive Api.Model.IdResult.decoder
        }


deleteAlias : Flags -> String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
deleteAlias flags id receive =
    Http2.authDelete
        { url = flags.config.baseUrl ++ "/api/v2/sec/alias/" ++ id
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


createAlias : Flags -> AliasChange -> (Result Http.Error IdResult -> msg) -> Cmd msg
createAlias flags ac receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v2/sec/alias"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.AliasChange.encode ac)
        , expect = Http.expectJson receive Api.Model.IdResult.decoder
        }


modifyAlias : Flags -> String -> AliasChange -> (Result Http.Error IdResult -> msg) -> Cmd msg
modifyAlias flags id ac receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v2/sec/alias/" ++ id
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.AliasChange.encode ac)
        , expect = Http.expectJson receive Api.Model.IdResult.decoder
        }


getAlias : Flags -> String -> (Result Http.Error AliasDetail -> msg) -> Cmd msg
getAlias flags id receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v2/sec/alias/" ++ id
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.AliasDetail.decoder
        }


listAlias : Flags -> String -> (Result Http.Error AliasList -> msg) -> Cmd msg
listAlias flags q receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v2/sec/alias?q=" ++ Url.percentEncode q
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.AliasList.decoder
        }


changePassword :
    Flags
    -> PasswordChange
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
changePassword flags pwc receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v2/sec/settings/password"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.PasswordChange.encode pwc)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


getEmail : Flags -> (Result Http.Error EmailInfo -> msg) -> Cmd msg
getEmail flags receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v2/sec/settings/email"
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.EmailInfo.decoder
        }


setEmail : Flags -> Maybe String -> (Result Http.Error BasicResult -> msg) -> Cmd msg
setEmail flags memail receive =
    let
        url =
            flags.config.baseUrl ++ "/api/v2/sec/settings/email"

        acc =
            getAccount flags

        exp =
            Http.expectJson receive Api.Model.BasicResult.decoder
    in
    case memail of
        Just email ->
            Http2.authPost
                { url = url
                , account = acc
                , body = Http.jsonBody (Api.Model.EmailChange.encode (EmailChange email))
                , expect = exp
                }

        Nothing ->
            Http2.authDelete
                { url = url
                , account = acc
                , expect = exp
                }


modifyAccount :
    Flags
    -> String
    -> AccountModify
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
modifyAccount flags id input receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v2/admin/account/" ++ id
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.AccountModify.encode input)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


createAccount : Flags -> AccountCreate -> (Result Http.Error BasicResult -> msg) -> Cmd msg
createAccount flags input receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v2/admin/account"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.AccountCreate.encode input)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


loadAccount : Flags -> String -> (Result Http.Error AccountDetail -> msg) -> Cmd msg
loadAccount flags id receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v2/admin/account/" ++ id
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.AccountDetail.decoder
        }


listAccounts : Flags -> String -> (Result Http.Error AccountList -> msg) -> Cmd msg
listAccounts flags q receive =
    Http2.authGet
        { url = flags.config.baseUrl ++ "/api/v2/admin/account?q=" ++ Url.percentEncode q
        , account = getAccount flags
        , expect = Http.expectJson receive Api.Model.AccountList.decoder
        }


register : Flags -> Registration -> (Result Http.Error BasicResult -> msg) -> Cmd msg
register flags reg receive =
    Http.post
        { url = flags.config.baseUrl ++ "/api/v2/open/signup/register"
        , body = Http.jsonBody (Api.Model.Registration.encode reg)
        , expect = Http.expectJson receive Api.Model.BasicResult.decoder
        }


newInvite : Flags -> GenInvite -> (Result Http.Error InviteResult -> msg) -> Cmd msg
newInvite flags req receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v2/admin/signup/newinvite"
        , account = getAccount flags
        , body = Http.jsonBody (Api.Model.GenInvite.encode req)
        , expect = Http.expectJson receive Api.Model.InviteResult.decoder
        }


login : Flags -> UserPass -> (Result Http.Error AuthResult -> msg) -> Cmd msg
login flags up receive =
    Http.post
        { url = flags.config.baseUrl ++ "/api/v2/open/auth/login"
        , body = Http.jsonBody (Api.Model.UserPass.encode up)
        , expect = Http.expectJson receive Api.Model.AuthResult.decoder
        }


logout : Flags -> (Result Http.Error () -> msg) -> Cmd msg
logout flags receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v2/sec/auth/logout"
        , account = getAccount flags
        , body = Http.emptyBody
        , expect = Http.expectWhatever receive
        }


loginSession : Flags -> (Result Http.Error AuthResult -> msg) -> Cmd msg
loginSession flags receive =
    Http2.authPost
        { url = flags.config.baseUrl ++ "/api/v2/sec/auth/session"
        , account = getAccount flags
        , body = Http.emptyBody
        , expect = Http.expectJson receive Api.Model.AuthResult.decoder
        }


versionInfo : Flags -> (Result Http.Error VersionInfo -> msg) -> Cmd msg
versionInfo flags receive =
    Http.get
        { url = flags.config.baseUrl ++ "/api/v2/open/info/version"
        , expect = Http.expectJson receive Api.Model.VersionInfo.decoder
        }


refreshSession : Flags -> (Result Http.Error AuthResult -> msg) -> Cmd msg
refreshSession flags receive =
    case flags.account of
        Just acc ->
            if acc.success && acc.validMs > 30000 then
                let
                    delay =
                        acc.validMs - 30000 |> toFloat
                in
                Http2.executeIn delay receive (refreshSessionTask flags)

            else
                Cmd.none

        Nothing ->
            Cmd.none


refreshSessionTask : Flags -> Task.Task Http.Error AuthResult
refreshSessionTask flags =
    Http2.authTask
        { url = flags.config.baseUrl ++ "/api/v2/sec/auth/session"
        , method = "POST"
        , headers = []
        , account = getAccount flags
        , body = Http.emptyBody
        , resolver = Http2.jsonResolver Api.Model.AuthResult.decoder
        , timeout = Nothing
        }


getAccount : Flags -> AuthResult
getAccount flags =
    Maybe.withDefault Api.Model.AuthResult.empty flags.account


oauthUrl : Flags -> OAuthItem -> String
oauthUrl flags item =
    flags.config.baseUrl ++ "/api/v2/open/auth/oauth/" ++ item.id
