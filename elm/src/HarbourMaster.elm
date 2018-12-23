module HarbourMaster exposing (main)

import Browser
import Html exposing (..)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)


type alias Model =
    { dummy : String
    , numContainersRunning : Int
    , serverErrMsg : String
    }


type Msg
    = GetDockerInfo
    | GotDockerInfo (Result Http.Error DockerInfo)


initialModel =
    { dummy = "Dummy"
    , numContainersRunning = 0
    , serverErrMsg = ""
    }


type alias DockerInfo =
    { id : String
    , numContainersRunning : Int
    , numContainersPaused : Int
    , numContainersStopped : Int
    , numImages : Int
    , driver : String
    }


dockerInfoDecoder : Decode.Decoder DockerInfo
dockerInfoDecoder =
    Decode.succeed DockerInfo
        |> required "ID" Decode.string
        |> required "ContainersRunning" Decode.int
        |> required "ContainersPaused" Decode.int
        |> required "ContainersStopped" Decode.int
        |> required "Images" Decode.int
        |> required "Driver" Decode.string


getDockerInfo : Cmd Msg
getDockerInfo =
    Http.get
        { url = "/api/docker-engine/?url=/info"
        , expect = Http.expectJson GotDockerInfo dockerInfoDecoder
        }


initialCmd : Cmd Msg
initialCmd =
    getDockerInfo


view : Model -> Html Msg
view model =
    div []
        [ text "App"
        , text <| "# of running containers: " ++ String.fromInt model.numContainersRunning
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotDockerInfo (Ok dockerInfo) ->
            ( { model | numContainersRunning = dockerInfo.numContainersRunning }, Cmd.none )

        GotDockerInfo (Err error) ->
            ( { model | serverErrMsg = "Server error" }, Cmd.none )

        GetDockerInfo ->
            ( model, getDockerInfo )


init : () -> ( Model, Cmd Msg )
init flags =
    ( initialModel, initialCmd )


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }
