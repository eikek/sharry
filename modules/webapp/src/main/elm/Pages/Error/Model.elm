module Pages.Error.Model exposing (..)

type alias Model =
    { message: String
    }

initModel: String -> Model
initModel msg =
    Model msg

emptyModel: Model
emptyModel = Model ""
