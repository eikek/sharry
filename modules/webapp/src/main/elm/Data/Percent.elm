module Data.Percent exposing (mkPercent)


mkPercent : Int -> Int -> Int
mkPercent c t =
    if t <= 0 then
        100

    else
        (toFloat c / toFloat t) * 100 |> round
