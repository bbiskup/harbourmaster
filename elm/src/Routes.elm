module Routes exposing (Route(..), containerPath, containersPath, imagePath, imagesPath, infoPath, parseUrl, pathFor)

import Url exposing (Url)
import Url.Parser exposing (..)


appPrefix : String
appPrefix =
    "app"


type Route
    = InfoRoute
    | ContainersRoute
    | ContainerRoute String
      --    | ContainerRoute String
    | ImagesRoute
    | ImageRoute String
    | NotFoundRoute


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ map InfoRoute (s appPrefix </> s "info")
        , map ContainerRoute (s appPrefix </> s "containers" </> string)
        , map ContainersRoute (s appPrefix </> s "containers")
        , map ImageRoute (s appPrefix </> s "images" </> string)
        , map ImagesRoute (s appPrefix </> s "images")
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

                ContainerRoute id ->
                    "/containers/" ++ id

                ContainersRoute ->
                    "/containers"

                ImageRoute id ->
                    "/images/" ++ id

                ImagesRoute ->
                    "/images"

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


containerPath : String -> String
containerPath id =
    pathFor <| ContainerRoute id


imagesPath : String
imagesPath =
    pathFor ImagesRoute


imagePath : String -> String
imagePath id =
    pathFor <| ImageRoute id
