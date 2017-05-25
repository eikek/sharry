module DataTest exposing (..)

import Expect
import Test exposing (Test, describe, test, fuzz)
import Fuzz exposing (string)

import Data

formatDate: Test
formatDate =
    describe "format date times"
        [ test "prepend zeros" <|
          \() ->
              "2017-05-21T12:03:03Z"
              |> Data.formatDate
              |> Expect.equal "Sun, 21. May 2017, 14:03"
        ]


parseDuration: Test
parseDuration =
    describe "parse java.time.Durations"
        [ test "hours" <|
          \() ->
              "PT96H"
              |> Data.parseDuration
              |> Expect.equal (Just (96, "h"))
        ]

formatDuration: Test
formatDuration =
    describe "format durations"
        [ test "hours" <|
            \() ->
                "PT12H"
                |> Data.formatDuration
                |> Expect.equal "12h"
        , test "days" <|
            \() ->
                "PT96H"
                |> Data.formatDuration
                |> Expect.equal "4d"
        ]
