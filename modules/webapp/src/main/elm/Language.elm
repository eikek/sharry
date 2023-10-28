module Language exposing
    ( Language(..)
    , allLanguages
    )


type Language
    = English
    | German
    | French
    | Japanese


allLanguages : List Language
allLanguages =
    [ English
    , German
    , French
    , Japanese
    ]
