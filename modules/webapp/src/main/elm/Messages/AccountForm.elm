module Messages.AccountForm exposing (AccountForm, gb)

-- AccountForm component texts


type alias AccountForm =
    { id : String
    , login : String
    , state : String
    , admin : String
    , password : String
    , submit : String
    , back : String
    }


gb : AccountForm
gb =
    { id = "Id"
    , login = "Login"
    , state = "State"
    , admin = "Admin"
    , password = "Password"
    , submit = "Submit"
    , back = "Back"
    }
