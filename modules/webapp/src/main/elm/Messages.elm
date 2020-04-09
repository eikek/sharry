module Messages exposing
    ( Account
    , Alias
    , Detail
    , Language(..)
    , Login
    , Messages
    , OpenDetail
    , OpenShare
    , Register
    , Share
    , allLanguages
    , fromFlags
    , get
    , toIso2
    )

import Data.Flags exposing (Flags)
import Messages.AccountForm
import Messages.AccountTable
import Messages.AliasForm
import Messages.AliasTable
import Messages.MailSend
import Messages.MarkdownInput
import Messages.ShareFileList
import Messages.YesNoDimmer


type Language
    = English


allLanguages : List Language
allLanguages =
    [ English
    ]


{-| Get a ISO-3166-1 code of the given lanugage.
-}
toIso2 : Language -> String
toIso2 lang =
    get lang |> .iso2


{-| Return the Language from given iso2 code. If the iso2 code is not
known, return Nothing.
-}
readIso2 : String -> Maybe Language
readIso2 iso =
    let
        isIso lang =
            iso == toIso2 lang
    in
    List.filter isIso allLanguages
        |> List.head


{-| Return the Language from the given iso2 code. If the iso2 code is
not known, return English as a default.
-}
fromIso2 : String -> Language
fromIso2 iso =
    readIso2 iso
        |> Maybe.withDefault English



-- Login page texts


type alias Login =
    { username : String
    , password : String
    , loginPlaceholder : String
    , passwordPlaceholder : String
    , loginButton : String
    , via : String
    , loginSuccessful : String
    , noAccount : String
    , signupLink : String
    }


loginGB : Login
loginGB =
    { username = "Username"
    , password = "Password"
    , loginPlaceholder = "Login"
    , passwordPlaceholder = "Password"
    , loginButton = "Login"
    , via = "via"
    , loginSuccessful = "Login successful"
    , noAccount = "No account?"
    , signupLink = "Sign up!"
    }



-- Register page texts


type alias Register =
    { signup : String
    , userLogin : String
    , password : String
    , passwordRepeat : String
    , invitationKey : String
    , submitButton : String
    , alreadySignedUp : String
    , signin : String
    , registrationSuccessful : String
    }


registerGB : Register
registerGB =
    { signup = "Sign up"
    , userLogin = "User Login"
    , password = "Password"
    , passwordRepeat = "Password (repeat)"
    , invitationKey = "Invitation Key"
    , submitButton = "Submit"
    , alreadySignedUp = "Already signed up?"
    , signin = "Sign in"
    , registrationSuccessful = "Registration successful."
    }



-- Account page texts


type alias Account =
    { createAccountTitle : String
    , accounts : String
    , searchPlaceholder : String
    , newAccount : String
    , accountForm : Messages.AccountForm.AccountForm
    , accountTable : Messages.AccountTable.AccountTable
    }


accountGB : Account
accountGB =
    { createAccountTitle = "Create a new internal account"
    , accounts = "Accounts"
    , searchPlaceholder = "Search…"
    , newAccount = "New Account"
    , accountForm = Messages.AccountForm.gb
    , accountTable = Messages.AccountTable.gb
    }



-- Alias page texts


type alias Alias =
    { createNew : String
    , aliasPage : String
    , aliasPages : String
    , newAliasPage : String
    , searchPlaceholder : String
    , errorQrCode : String
    , shareThisLink : String
    , aliasPageNowAt : String
    , shareThisUrl : String
    , sendEmail : String
    , aliasForm : Messages.AliasForm.AliasForm
    , aliasTable : Messages.AliasTable.AliasTable
    , mailSend : Messages.MailSend.MailSend
    }


aliasGB : Alias
aliasGB =
    { createNew = "Create New Alias Page"
    , aliasPage = "Alias Page: "
    , aliasPages = "Alias Pages"
    , newAliasPage = "New Alias Page"
    , searchPlaceholder = "Search…"
    , errorQrCode = "Error while encoding to QRCode."
    , shareThisLink = "Share this link"
    , aliasPageNowAt = "The alias page is now at: "
    , shareThisUrl = "You can share this URL with others to receive files from them."
    , sendEmail = "Send E-Mail"
    , aliasForm = Messages.AliasForm.gb
    , aliasTable = Messages.AliasTable.gb
    , mailSend = Messages.MailSend.gb
    }



-- Detail page texts


type alias Detail =
    { mailSend : Messages.MailSend.MailSend
    , save : String
    , markdownInput : Messages.MarkdownInput.MarkdownInput
    , shareFileList : Messages.ShareFileList.ShareFileList
    , yesNo : Messages.YesNoDimmer.YesNoDimmer
    , sharePublished : String
    , shareNotPublished : String
    , shareLinkExpired : String
    , errorQrCode : String
    , sharePublicAvailableAt : String
    , shareAsYouLike : String
    , sendEmail : String
    , name : String
    , validity : String
    , maxViews : String
    , password : String
    , passwordProtected : String
    , passwordNone : String
    , shareSize : String
    , created : String
    , aliasLabel : String
    , publishedOn : String
    , publishedUntil : String
    , lastAccess : String
    , views : String
    , publishWithNewLink : String
    , delete : String
    , edit : String
    , detailsMenu : String
    , shareLinkMenu : String
    , editDescription : String
    , publish : String
    , unpublish : String
    , listView : String
    , cardView : String
    , submit : String
    , clear : String
    , resume : String
    , pause : String
    , uploadsGreaterThan : String -> String
    , waitDeleteShare : String
    , loadingData : String
    }


detailGB : Detail
detailGB =
    { mailSend = Messages.MailSend.gb
    , save = "Save"
    , markdownInput = Messages.MarkdownInput.gb
    , shareFileList = Messages.ShareFileList.gb
    , yesNo = Messages.YesNoDimmer.gb
    , sharePublished =
        "The share has been published, but its max-views has been reached. You can "
            ++ "increase this property if you want to have this published for another while."
    , shareNotPublished =
        "In order to share this with others, you need to publish "
            ++ "this share. Then everyone you'll send the generated link "
            ++ "can access this data."
    , shareLinkExpired =
        "The share has been published, but it is now expired. You can "
            ++ "first unpublish and then publish it again."
    , errorQrCode = "Error while encoding to QRCode."
    , sharePublicAvailableAt = "The share is publicly available at"
    , shareAsYouLike = "You can share this link to all you'd like to access this data."
    , sendEmail = "Send E-Mail"
    , name = "Name"
    , validity = "Validity Time"
    , maxViews = "Max. Views"
    , password = "Password"
    , passwordProtected = "Password Protected"
    , passwordNone = "None"
    , shareSize = "#/Size"
    , created = "Created"
    , aliasLabel = "Alias"
    , publishedOn = "Published on"
    , publishedUntil = "Published until"
    , lastAccess = "Last Access"
    , views = "Views"
    , publishWithNewLink = "Publish with new Link"
    , delete = "Delete"
    , edit = "Edit"
    , detailsMenu = "Details"
    , shareLinkMenu = "Share Link"
    , editDescription = "Edit description"
    , publish = "Publish"
    , unpublish = "Unpublish"
    , listView = "List View"
    , cardView = "Card View"
    , submit = "Submit"
    , clear = "Clear"
    , resume = "Resume"
    , pause = "Pause"
    , uploadsGreaterThan =
        \size ->
            "All uploads must not be greater than " ++ size ++ "."
    , waitDeleteShare = "Deleting share. Please wait."
    , loadingData = "Loading data..."
    }



-- OpenDetail page texts


type alias OpenDetail =
    Detail


openDetailGB : OpenDetail
openDetailGB =
    detailGB



-- Share page texts


type alias Share =
    { markdownInput : Messages.MarkdownInput.MarkdownInput
    }


shareGB : Share
shareGB =
    { markdownInput = Messages.MarkdownInput.gb
    }



-- OpenShare page texts


type alias OpenShare =
    Share


openShareGB : OpenShare
openShareGB =
    shareGB



-- Messages


{-| The messages record contains all strings used in the application.
-}
type alias Messages =
    { iso2 : String
    , label : String
    , flagIcon : String
    , login : Login
    , register : Register
    , account : Account
    , aliasPage : Alias
    , detail : Detail
    , openShare : OpenShare
    , share : Share
    , openDetail : OpenDetail
    }


get : Language -> Messages
get lang =
    case lang of
        English ->
            gb


fromFlags : Flags -> Messages
fromFlags flags =
    Maybe.map fromIso2 flags.language
        |> Maybe.withDefault English
        |> get


gb : Messages
gb =
    { iso2 = "gb"
    , label = "English"
    , flagIcon = "gb uk flag"
    , login = loginGB
    , register = registerGB
    , account = accountGB
    , aliasPage = aliasGB
    , detail = detailGB
    , openShare = openShareGB
    , share = shareGB
    , openDetail = openDetailGB
    }
