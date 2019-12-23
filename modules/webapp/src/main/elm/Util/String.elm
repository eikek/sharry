module Util.String exposing (shorten)


shorten : Int -> String -> String
shorten max str =
    let
        len =
            max // 2

        pref =
            String.left len str

        suff =
            String.right len str
    in
    pref ++ "…" ++ suff
