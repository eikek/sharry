module Page.Info.Data exposing (..)


type alias Mesg =
    { head : String
    , text : String
    }


type alias Model =
    List Mesg


emptyModel : Model
emptyModel =
    [ { head = "Forbidden"
      , text = """
You don't have enough permission to access this site.
"""
      }
    , { head = "Expired"
      , text = "This resource is expired or doesn't exist."
      }
    ]


type Msg
    = Dummy
