module UtilTest exposing (suite)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)


suite : Test
suite =
    test "Test 1" <|
        \_ -> Expect.equal (1 + 1) 2
