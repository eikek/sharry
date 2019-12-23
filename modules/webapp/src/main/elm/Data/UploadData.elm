module Data.UploadData exposing (UploadData, encode)

import Json.Decode as D
import Json.Encode as E


{-| Values of this type are send via ports to JS to run chunked
uploads via tus-js-client library.
-}
type alias UploadData =
    { url : String
    , id : String
    , files : List D.Value
    , aliasId : Maybe String
    }


encode : UploadData -> D.Value
encode data =
    E.object
        [ ( "url", E.string data.url )
        , ( "id", E.string data.id )
        , ( "files", E.list identity data.files )
        , ( "aliasId"
          , Maybe.map E.string data.aliasId
                |> Maybe.withDefault E.null
          )
        ]
