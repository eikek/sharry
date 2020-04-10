module Messages.DetailPage exposing
    ( Texts
    , gb
    )

import Messages.Dropzone2
import Messages.MailSend
import Messages.MarkdownInput
import Messages.ShareFileList
import Messages.ValidityField
import Messages.YesNoDimmer


type alias Texts =
    { mailSend : Messages.MailSend.Texts
    , save : String
    , markdownInput : Messages.MarkdownInput.Texts
    , shareFileList : Messages.ShareFileList.Texts
    , yesNo : Messages.YesNoDimmer.Texts
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
    , dropzone : Messages.Dropzone2.Texts
    , validityField : Messages.ValidityField.Texts
    , passwordRequired : String
    , passwordInvalid : String
    }


gb : Texts
gb =
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
    , dropzone = Messages.Dropzone2.gb
    , validityField = Messages.ValidityField.gb
    , passwordRequired = "Password required"
    , passwordInvalid = "Password invalid"
    }
