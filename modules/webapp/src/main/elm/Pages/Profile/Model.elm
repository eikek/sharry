module Pages.Profile.Model exposing (..)

import Data exposing (Account, RemoteUrls)
import Widgets.UpdateEmailForm as UpdateEmailForm
import Widgets.UpdatePasswordForm as UpdatePasswordForm

type alias Model =
    {updateEmail: UpdateEmailForm.Model
    ,updatePassword: UpdatePasswordForm.Model
    ,name: String
    }

makeModel: RemoteUrls -> Account -> Model
makeModel urls acc =
    Model (UpdateEmailForm.makeModel acc urls) (UpdatePasswordForm.makeModel acc urls) acc.login


type Msg
    = UpdateEmailFormMsg UpdateEmailForm.Msg
    | UpdatePasswordFormMsg UpdatePasswordForm.Msg
