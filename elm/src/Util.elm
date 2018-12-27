module Util exposing (bytesToMiB, lastElem)

{-| General utilities
-}


{-| Convert a number of bytes to MiB (Mebibytes), truncating the result to the nearest integer.
-}
bytesToMiB : Int -> Int
bytesToMiB bytes =
    bytes
        |> toFloat
        |> (*) (1 / 1024 / 1024)
        |> round


lastElem : List a -> Maybe a
lastElem =
    List.foldl (Just >> always) Nothing
