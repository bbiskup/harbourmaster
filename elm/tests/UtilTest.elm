module UtilTest exposing (byteToMiBSuite, lastElemSuite, timestampFormatterSuite)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import Time
import Util as Sut


byteToMiBSuite : Test
byteToMiBSuite =
    describe "Function byteToMiBSuite"
        [ test "0 bytes -> 0 MiB" <|
            \_ ->
                Expect.equal (Sut.bytesToMiB 0) 0
        , test "Exactly 1 MiB" <|
            \_ -> Expect.equal (Sut.bytesToMiB <| 1024 ^ 2) 1
        , test "Rounding down (exactly below 1 MiB threshold)" <|
            \_ -> Expect.equal (Sut.bytesToMiB <| 1024 ^ 2 - 1) 0
        , test "Rounding down to 1 MiB" <|
            \_ -> Expect.equal (Sut.bytesToMiB 1024 ^ 2 + 1) 1
        , test "Negative size gets normalized to 0" <|
            \_ -> Expect.equal (Sut.bytesToMiB -1) 0
        ]


lastElemSuite : Test
lastElemSuite =
    describe "Function lastElem" <|
        [ test "Multiple elements"
            (\_ ->
                Expect.equal (Sut.lastElem [ 1, 2, 3 ]) (Just 3)
            )
        , test "A single element" <|
            \_ ->
                Expect.equal (Sut.lastElem [ 1 ]) (Just 1)
        , test "Empty list should return Nothing" <|
            \_ ->
                Expect.equal (Sut.lastElem []) Nothing
        ]


timestampFormatterSuite : Test
timestampFormatterSuite =
    let
        createTimestamp : Int -> String
        createTimestamp time =
            time
                |> (*) 1000
                |> Time.millisToPosix
                |> Sut.timestampFormatter Time.utc
    in
    describe "Function timestampFormatter" <|
        [ test "Epoch"
            (\_ ->
                Expect.equal (createTimestamp 0) "1970-01-01 00:00"
            )
        , test "2018-05-20T19:17:41Z"
            (\_ ->
                Expect.equal (createTimestamp 1526843861) "2018-05-20 19:17"
            )
        ]
