module Messages.AliasForm exposing
    ( AliasForm
    , gb
    )

import Html exposing (..)
import Messages.YesNoDimmer exposing (YesNoDimmer)


type alias AliasForm =
    { id : String
    , noteToIdsHead : String
    , noteToIds : Html Never
    , name : String
    , validity : String
    , enabled : String
    , submit : String
    , back : String
    , delete : String
    , yesNo : YesNoDimmer
    }


gb : AliasForm
gb =
    { id = "Id"
    , noteToIdsHead = "Note to Ids"
    , noteToIds =
        p []
            [ text "This ID is part of the url where "
            , em [] [ text "everyone" ]
            , text " can upload files. It is recommended to use"
            , text " something random. The id can be changed to "
            , text "any value, but if it is left empty, a random "
            , text "one will be generated."
            ]
    , name = "Name"
    , validity = "Validity"
    , enabled = "Enabled"
    , submit = "Submit"
    , back = "Back"
    , delete = "Delete"
    , yesNo = Messages.YesNoDimmer.gb
    }
