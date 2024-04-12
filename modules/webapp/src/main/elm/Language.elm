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

allLanguages : List Language
allLanguages =
    [ English
    , German
    , French
    , Japanese
    , Czech
    ]
