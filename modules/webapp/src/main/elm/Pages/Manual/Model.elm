module Pages.Manual.Model exposing (..)

type alias Model =
    { manualPage: String
    }

initialModel: Model
initialModel = Model "index.md"

makeModel: String -> Model
makeModel page =
    Model page

type Msg
    = Content String


update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Content str ->
            {model | manualPage = str} ! []
