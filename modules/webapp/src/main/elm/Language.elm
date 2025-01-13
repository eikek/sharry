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
    | Italian

allLanguages : List Language
allLanguages =
    [ English
    , German
    , French
    , Japanese
    , Czech
    , Spanish
    , Italian
    ]
