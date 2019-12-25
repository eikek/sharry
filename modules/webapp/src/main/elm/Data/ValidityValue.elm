module Data.ValidityValue exposing
    ( ValidityValue(..)
    , gte
    , lte
    , sub
    , toMillis
    )


type ValidityValue
    = Millis Int
    | Minutes Int
    | Hours Int
    | Days Int


toMillis : ValidityValue -> Int
toMillis v =
    case v of
        Millis n ->
            n

        Minutes n ->
            n * minutesToMillis

        Hours n ->
            n * hourToMillis

        Days n ->
            n * dayToMillis


sub : ValidityValue -> ValidityValue -> Int
sub v1 v2 =
    toMillis v1 - toMillis v2


lte : ValidityValue -> ValidityValue -> Bool
lte v1 v2 =
    toMillis v1 <= toMillis v2


gte : ValidityValue -> ValidityValue -> Bool
gte v1 v2 =
    lte v2 v1


minutesToMillis : Int
minutesToMillis =
    60 * 1000


hourToMillis : Int
hourToMillis =
    60 * 60 * 1000


dayToMillis : Int
dayToMillis =
    24 * hourToMillis
