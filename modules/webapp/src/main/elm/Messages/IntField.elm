module Messages.IntField exposing
    ( Texts
    , de
    , gb
    , fr
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

fr : Texts
fr =
    { mustBeLower = "Le nombre doit être <= "
    , mustBeGreater = "Le nombre doit être >= "
    , notANumber = \str -> "'" ++ str ++ "' n'est pas un nombre valide !"
    }
