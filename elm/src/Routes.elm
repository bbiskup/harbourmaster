module Routes exposing (Route(..), containerPath, containersPath, imagePath, imagesPath, infoPath, parseUrl)

import Url exposing (Url)
import Url.Parser exposing (..)


appPrefix : String
appPrefix =
    "app"


type Route
    = InfoRoute
    | ContainersRoute
      --    | ContainerRoute String
    | ImagesRoute
    | ImageRoute String
    | NotFoundRoute


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ map InfoRoute (s appPrefix </> s "info")
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

                ContainersRoute ->
                    "/containers"

                {- ContainerRoute id ->
                   "/containers/" ++ id
                -}
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
    pathFor ContainersRoute ++ "/" ++ id


imagesPath : String
imagesPath =
    pathFor ImagesRoute


imagePath : String -> String
imagePath id =
    pathFor <| ImageRoute id
