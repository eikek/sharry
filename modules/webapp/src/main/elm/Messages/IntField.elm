module Messages.IntField exposing
    ( Texts
    , de
    , gb
    )


type alias Texts =
    { mustBeLower : String
    , mustBeGreater : String
    , notANumber : String -> String
    }


gb : Texts
gb =
    { mustBeLower = "Number must be <= "
    , mustBeGreater = "Number must be >= "
    , notANumber = \str -> "'" ++ str ++ "' is not a valid number!"
    }


de : Texts
de =
    { mustBeLower = "Zahl muss <= "
    , mustBeGreater = "Zahl muss >= "
    , notANumber = \str -> "'" ++ str ++ "' ist keine Zahl!"
    }
