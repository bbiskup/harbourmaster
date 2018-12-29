module UtilTest exposing (byteToMiBSuite)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
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
        ]
