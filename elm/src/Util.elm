module Util exposing (bytesToMiB, lastElem, viewSection)

{-| General utilities
-}

import Bootstrap.Table as Table
import Html exposing (..)
import Html.Attributes exposing (style)


{-| Convert a number of bytes to MiB (Mebibytes), truncating the result to the nearest integer.
-}
bytesToMiB : Int -> Int
bytesToMiB bytes =
    if bytes < 0 then
        0

    else
        bytes
            |> toFloat
            |> (*) (1 / 1024 / 1024)
            |> floor


{-| Get last element of List, or Nothing if the ist is empty
-}
lastElem : List a -> Maybe a
lastElem =
    List.foldl (Just >> always) Nothing


{-| Display tabular data
-}
viewSection : String -> List ( String, Html msg ) -> Html msg
viewSection title data =
    let
        tableRow : ( String, Html msg ) -> Table.Row msg
        tableRow ( col1, col2 ) =
            Table.tr []
                [ Table.th [ Table.cellAttr <| style "width" "20%" ] [ text col1 ]
                , Table.td [ Table.cellAttr <| style "width" "80%" ] [ col2 ]
                ]

        sectionTable : Html msg
        sectionTable =
            Table.table
                { options = [ Table.striped, Table.hover, Table.small ]
                , thead =
                    Table.simpleThead []
                , tbody =
                    Table.tbody [] (List.map tableRow data)
                }
    in
    div []
        [ h5 [] [ text title ]
        , sectionTable
        ]
