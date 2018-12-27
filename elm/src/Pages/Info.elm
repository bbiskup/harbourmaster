module Pages.Info exposing (Model, Msg(..), init, initialCmd, subscriptions, update, view)

{- Visualization of 'docker info' -}

import Bootstrap.Table as Table
import Html exposing (Html, div, h1, h5, text)
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
    , osType : String
    , os : String
    , kernelVersion : String
    , daemonID : String
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
        |> required "OSType" Decode.string
        |> required "OperatingSystem" Decode.string
        |> required "KernelVersion" Decode.string
        |> required "ID" Decode.string
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


viewSection : DockerInfo -> String -> List ( String, String ) -> Html Msg
viewSection info title data =
    let
        tableRow ( col1, col2 ) =
            Table.tr []
                [ Table.th [] [ text col1 ]
                , Table.td [] [ text col2 ]
                ]

        sectionTable : Html Msg
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


view : Model -> Html Msg
view model =
    let
        content : List (Html Msg)
        content =
            case model.dockerInfo of
                Just info ->
                    let
                        containersData =
                            [ ( "# running", String.fromInt info.numContainersRunning )
                            , ( "# stopped", String.fromInt info.numContainersStopped )
                            , ( "# paused", String.fromInt info.numContainersPaused )
                            ]

                        osData =
                            [ ( "Operating system type", info.osType )
                            , ( "Operating system", info.os )
                            , ( "Kernel version", info.kernelVersion )
                            ]

                        serverData =
                            [ ( "Docker daemon ID ", info.daemonID )
                            ]
                    in
                    List.map (\( title, data ) -> viewSection info title data)
                        [ ( "Containers", containersData )
                        , ( "Operating system", osData )
                        , ( "Server", serverData )
                        ]

                Nothing ->
                    [ text "loading..." ]
    in
    div []
        (h1 [] [ text "Info" ]
            :: content
        )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
