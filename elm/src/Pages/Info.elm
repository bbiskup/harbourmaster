module Pages.Info exposing (Model, Msg(..), init, initialCmd, subscriptions, update, view)

{- Visualization of 'docker info' -}

import Html exposing (Html, div, h1, text)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)


type alias Model =
    { dockerInfo : Maybe DockerInfo
    , serverErrMsg : String
    }


type Msg
    = GetDockerInfo
    | GotDockerInfo (Result Http.Error DockerInfo)


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


init : ( Model, Cmd Msg )
init =
    ( { dockerInfo = Nothing
      , serverErrMsg = ""
      }
    , initialCmd
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotDockerInfo (Ok dockerInfo) ->
            ( { model | dockerInfo = Just dockerInfo }, Cmd.none )

        GotDockerInfo (Err error) ->
            ( { model | serverErrMsg = "Server error" }, Cmd.none )

        GetDockerInfo ->
            ( model, getDockerInfo )


view : Model -> Html Msg
view model =
    let
        content : List (Html Msg)
        content =
            case model.dockerInfo of
                Just info ->
                    [ text "App"
                    , text <| "# of running containers: " ++ String.fromInt info.numContainersRunning
                    ]

                Nothing ->
                    [ text "loading..." ]
    in
    div []
        (h1 [] [ text "Images" ]
            :: content
        )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
