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


viewContainersSection : DockerInfo -> Html Msg
viewContainersSection info =
    let
        tableRow ( col1, col2 ) =
            Table.tr []
                [ Table.th [] [ text col1 ]
                , Table.td [] [ text col2 ]
                ]

        tableData =
            [ ( "# running", String.fromInt info.numContainersRunning )
            , ( "# stopped", String.fromInt info.numContainersStopped )
            , ( "# paused", String.fromInt info.numContainersPaused )
            ]

        containersTable : Html Msg
        containersTable =
            Table.table
                { options = [ Table.striped, Table.hover, Table.small ]
                , thead =
                    Table.simpleThead []
                , tbody =
                    Table.tbody [] (List.map tableRow tableData)
                }
    in
    div []
        [ h5 [] [ text "Containers" ]
        , containersTable
        ]


viewOSSection : DockerInfo -> Html Msg
viewOSSection info =
    let
        tableRow ( col1, col2 ) =
            Table.tr []
                [ Table.th [] [ text col1 ]
                , Table.td [] [ text col2 ]
                ]

        tableData =
            [ ( "Daemon ID", info.daemonID )
            ]

        osTable : Html Msg
        osTable =
            Table.table
                { options = [ Table.striped, Table.hover, Table.small ]
                , thead =
                    Table.simpleThead []
                , tbody =
                    Table.tbody [] (List.map tableRow tableData)
                }
    in
    div []
        [ h5 [] [ text "Operating System" ]
        , osTable
        ]


view : Model -> Html Msg
view model =
    let
        content : List (Html Msg)
        content =
            case model.dockerInfo of
                Just info ->
                    List.map (\f -> f info)
                        [ viewContainersSection
                        , viewOSSection
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
