module Routes exposing (Route(..), parseUrl)

import Url exposing (Url)
import Url.Parser exposing (..)


type Route
    = InfoRoute
    | ContainersRoute
      --    | ContainerRoute String
    | NotFoundRoute


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ map InfoRoute (s "app" </> s "info")
        , map ContainersRoute (s "app" </> s "containers")
        ]


parseUrl : Url -> Route
parseUrl url =
    case parse matchers url of
        Just route ->
            route

        Nothing ->
            NotFoundRoute


pathFor : Route -> String
pathFor route =
    case route of
        InfoRoute ->
            "/info"

        ContainersRoute ->
            "/containers"

        {- ContainerRoute id ->
           "/containers/" ++ id
        -}
        NotFoundRoute ->
            "/"
