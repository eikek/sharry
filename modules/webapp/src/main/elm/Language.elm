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
    | Portuguese

allLanguages : List Language
allLanguages =
    [ English
    , German
    , French
    , Japanese
    , Czech
    , Spanish
    , Italian
    , Portuguese
    ]
