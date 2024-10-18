module Language exposing
    ( Language(..)
    , allLanguages
    )


type Language
    = English
    | German
    | French
    | Japanese
    | Czech
    | Spanish

allLanguages : List Language
allLanguages =
    [ English
    , German
    , French
    , Japanese
    , Czech
    , Spanish
    ]
