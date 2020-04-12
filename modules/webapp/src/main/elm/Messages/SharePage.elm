module Messages.SharePage exposing
    ( Texts
    , gb
    )

import Messages.Dropzone2
import Messages.IntField
import Messages.MarkdownInput
import Messages.ValidityField


type alias Texts =
    { markdownInput : Messages.MarkdownInput.Texts
    , dropzone : Messages.Dropzone2.Texts
    , validityField : Messages.ValidityField.Texts
    , intField : Messages.IntField.Texts
    , sendFiles : String
    , description : String
    , sendMoreFiles : String
    , allFilesUploaded : String
    , someFilesFailedHeader : String
    , someFilesFailedText : String
    , someFilesFailedTextAddon : String
    , submit : String
    , clearFiles : String
    , resume : String
    , pause : String
    , password : String
    , createShare : String
    , details : String
    , name : String
    , namePlaceholder : String
    , validity : String
    , files : String
    , newShare : String
    , gotoShare : String
    , maxPublicViews : String
    }


gb : Texts
gb =
    { markdownInput = Messages.MarkdownInput.gb
    , dropzone = Messages.Dropzone2.gb
    , validityField = Messages.ValidityField.gb
    , intField = Messages.IntField.gb
    , sendFiles = "Send files"
    , description = "Description"
    , sendMoreFiles = "Send more files"
    , allFilesUploaded = "All files uploaded"
    , someFilesFailedHeader = "Some files failed"
    , someFilesFailedText = "Some files failed to upload…. You can try uploading them again. "
    , someFilesFailedTextAddon = "Go to the share and submit the same file again."
    , submit = "Submit"
    , clearFiles = "Clear Files"
    , resume = "Resume"
    , pause = "Pause"
    , password = "Password"
    , createShare = "Create a Share"
    , details = "Details"
    , name = "Name"
    , namePlaceholder = "Optional Name"
    , validity = "Validity"
    , files = "Files"
    , newShare = "New Share"
    , gotoShare = "Goto Share"
    , maxPublicViews = "Maximum Public Views"
    }
