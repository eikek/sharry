module Util.Size exposing (SizeUnit(..), bytesReadable, exactBytes)


type SizeUnit
    = G
    | M
    | K
    | B


prettyNumber : Float -> String
prettyNumber n =
    let
        parts =
            String.split "." (String.fromFloat n)
    in
    case parts of
        n0 :: d :: [] ->
            n0 ++ "." ++ String.left 2 d

        _ ->
            String.join "." parts


bytesReadable : SizeUnit -> Float -> String
bytesReadable unit n =
    let
        k =
            n / 1024

        num =
            prettyNumber n
    in
    case unit of
        G ->
            num ++ "G"

        M ->
            if k > 1 then
                bytesReadable G k

            else
                num ++ "M"

        K ->
            if k > 1 then
                bytesReadable M k

            else
                num ++ "K"

        B ->
            if k > 1 then
                bytesReadable K k

            else
                num ++ "B"


groupThousands : String -> String
groupThousands digits =
    let
        len =
            String.length digits

        headLen =
            case modBy 3 len of
                0 ->
                    3

                r ->
                    r
    in
    if len <= 3 then
        digits

    else
        String.left headLen digits ++ " " ++ groupThousands (String.dropLeft headLen digits)


exactBytes : Int -> String
exactBytes n =
    groupThousands (String.fromInt n) ++ " B"
