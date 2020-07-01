module Language exposing
    ( Language(..)
    , allLanguages
    )


type Language
    = English
    | German
    | French


allLanguages : List Language
allLanguages =
    [ English
    , German
    , French
    ]
