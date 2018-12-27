module Pages.Info exposing (Model, Msg(..), init, initialCmd, subscriptions, update, view)

{- Visualization of 'docker info' -}

import Bootstrap.Table as Table
import Html exposing (Html, div, h1, h5, text)
import Html.Attributes exposing (style)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Util exposing (bytesToMiB)


type alias Model =
    { dockerInfo : Maybe DockerInfo
    , serverErrMsg : String
    }


type Msg
    = GetDockerInfo
    | GotDockerInfo (Result Http.Error DockerInfo)


type alias DockerInfo =
    { -- Containers & images
      containersNumRunning : Int
    , containersNumPaused : Int
    , containersNumStopped : Int
    , imagesNum : Int

    -- OS
    , osType : String
    , os : String
    , osKernelVersion : String
    , osArchitecture : String

    -- Hardware
    , hwNumCPUs : Int
    , hwMemTotal : Int

    -- Server
    , serverDaemonID : String
    , serverVersion : String
    , serverDriver : String
    }


dockerInfoDecoder : Decode.Decoder DockerInfo
dockerInfoDecoder =
    Decode.succeed DockerInfo
        -- Containbrs & images
        |> required "ContainersRunning" Decode.int
        |> required "ContainersPaused" Decode.int
        |> required "ContainersStopped" Decode.int
        |> required "Images" Decode.int
        -- OS
        |> required "OSType" Decode.string
        |> required "OperatingSystem" Decode.string
        |> required "KernelVersion" Decode.string
        |> required "Architecture" Decode.string
        -- Hardware
        |> required "NCPU" Decode.int
        |> required "MemTotal" Decode.int
        -- Server
        |> required "ID" Decode.string
        |> required "ServerVersion" Decode.string
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
                [ Table.th [ Table.cellAttr <| style "width" "20%" ] [ text col1 ]
                , Table.td [ Table.cellAttr <| style "width" "80%" ] [ text col2 ]
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
                            [ ( "# running", String.fromInt info.containersNumRunning )
                            , ( "# stopped", String.fromInt info.containersNumStopped )
                            , ( "# paused", String.fromInt info.containersNumPaused )
                            ]

                        osData =
                            [ ( "Operating system type", info.osType )
                            , ( "Operating system", info.os )
                            , ( "Kernel version", info.osKernelVersion )
                            , ( "Architecture", info.osArchitecture )
                            ]

                        hardwareData =
                            [ ( "# of CPUs", String.fromInt info.hwNumCPUs )
                            , ( "Memory (MiB)", String.fromInt <| bytesToMiB info.hwMemTotal )
                            ]

                        serverData =
                            [ ( "Docker daemon ID ", info.serverDaemonID )
                            , ( "Version ", info.serverVersion )
                            ]
                    in
                    List.map (\( title, data ) -> viewSection info title data)
                        [ ( "Containers", containersData )
                        , ( "Operating system", osData )
                        , ( "Hardware", hardwareData )
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
