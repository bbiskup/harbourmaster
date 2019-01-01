module Routes exposing
    ( Route(..)
    , containerPath
    , containersPath
    , imagePath
    , imagesPath
    , infoPath
    , loginPath
    , parseUrl
    , pathFor
    )

import Url exposing (Url)
import Url.Parser exposing (..)


appPrefix : String
appPrefix =
    "app"


type Route
    = LoginRoute
    | InfoRoute
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
        , map LoginRoute (s appPrefix </> s "login")
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
                LoginRoute ->
                    "/login"

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


loginPath : String
loginPath =
    pathFor LoginRoute


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
