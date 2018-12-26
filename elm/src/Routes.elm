module Routes exposing (Route(..), containersPath, infoPath, parseUrl)

import Url exposing (Url)
import Url.Parser exposing (..)


appPrefix : String
appPrefix =
    "app"


type Route
    = InfoRoute
    | ContainersRoute
      --    | ContainerRoute String
    | NotFoundRoute


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ map InfoRoute (s appPrefix </> s "info")
        , map ContainersRoute (s appPrefix </> s "containers")
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
    let
        urlSuffix =
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
    in
    "/" ++ appPrefix ++ urlSuffix


infoPath : String
infoPath =
    pathFor InfoRoute


containersPath : String
containersPath =
    pathFor ContainersRoute
