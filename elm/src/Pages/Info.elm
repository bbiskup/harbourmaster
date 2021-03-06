module Pages.Info exposing (Model, Msg(..), init, initialCmd, subscriptions, update, view)

{- Visualization of 'docker info' -}

import Bootstrap.Grid.Col as Col
import Bootstrap.Table as Table
import Dict exposing (Dict)
import Html exposing (Html, b, div, h1, h5, li, p, text, ul)
import Html.Attributes exposing (class, style)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Types exposing (UpdateAppState(..), httpErrorToAppMessage)
import Util exposing (bytesToMiB, createEngineApiUrl, viewSection)


type alias Model =
    { dockerInfo : Maybe DockerInfo
    }


type Msg
    = GetDockerInfo
    | GotDockerInfo (Result Http.Error DockerInfo)


type alias Plugins =
    Dict String (Maybe (List String))


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
    , hostName : String

    -- Hardware
    , hwNumCPUs : Int
    , hwMemTotal : Int

    -- Docker engine
    , engineDaemonID : String
    , engineVersion : String
    , engineDriver : String
    , plugins : Plugins
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
        |> required "Name" Decode.string
        -- Hardware
        |> required "NCPU" Decode.int
        |> required "MemTotal" Decode.int
        -- Docker engine
        |> required "ID" Decode.string
        |> required "ServerVersion" Decode.string
        |> required "Driver" Decode.string
        |> required "Plugins" (Decode.dict (Decode.nullable (Decode.list Decode.string)))


getDockerInfo : Cmd Msg
getDockerInfo =
    Http.get
        { url = createEngineApiUrl "/info" Nothing
        , expect = Http.expectJson GotDockerInfo dockerInfoDecoder
        }


initialCmd : Cmd Msg
initialCmd =
    getDockerInfo


init : ( Model, Cmd Msg )
init =
    ( { dockerInfo = Nothing
      }
    , initialCmd
    )


update : Msg -> Model -> ( Model, Cmd Msg, UpdateAppState )
update msg model =
    case msg of
        GotDockerInfo (Ok dockerInfo) ->
            ( { model | dockerInfo = Just dockerInfo }
            , Cmd.none
            , NoOp
            )

        GotDockerInfo (Err error) ->
            ( model
            , Cmd.none
            , AddAppMessage <| httpErrorToAppMessage error
            )

        GetDockerInfo ->
            ( model, getDockerInfo, NoOp )


viewPlugins : Plugins -> Html Msg
viewPlugins plugins =
    let
        renderPluginSection : ( String, Maybe (List String) ) -> Html Msg
        renderPluginSection ( pluginSection, maybePlugins ) =
            let
                pluginsStr =
                    case maybePlugins of
                        Just pluginNames ->
                            String.join ", " pluginNames

                        Nothing ->
                            "-"
            in
            li []
                [ b [] [ text <| pluginSection ++ ": " ]
                , text pluginsStr
                ]
    in
    ul [ class "harbourmaster-plugin-list" ]
        (List.map renderPluginSection <| Dict.toList plugins)


view : Model -> Html Msg
view model =
    let
        content : List (Html Msg)
        content =
            case model.dockerInfo of
                Just info ->
                    let
                        containersData =
                            [ ( "# running", text <| String.fromInt info.containersNumRunning )
                            , ( "# stopped", text <| String.fromInt info.containersNumStopped )
                            , ( "# paused", text <| String.fromInt info.containersNumPaused )
                            ]

                        osData =
                            [ ( "Operating system type", text <| info.osType )
                            , ( "Operating system", text <| info.os )
                            , ( "Kernel version", text <| info.osKernelVersion )
                            , ( "Architecture", text <| info.osArchitecture )
                            , ( "Hostname ", text <| info.hostName )
                            ]

                        hardwareData =
                            [ ( "# of CPUs", text <| String.fromInt info.hwNumCPUs )
                            , ( "Memory (MiB)", text <| String.fromInt <| bytesToMiB info.hwMemTotal )
                            ]

                        engineData =
                            [ ( "Docker daemon ID ", text <| info.engineDaemonID )
                            , ( "Version ", text <| info.engineVersion )
                            , ( "Plugins ", viewPlugins info.plugins )
                            ]
                    in
                    List.map (\( title, data ) -> viewSection title data)
                        [ ( "Containers", containersData )
                        , ( "Operating system", osData )
                        , ( "Hardware", hardwareData )
                        , ( "Docker engine", engineData )
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
