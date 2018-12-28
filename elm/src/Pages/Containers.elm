module Pages.Containers exposing (Model, Msg, init, subscriptions, update, view)

{-| Container list view
-}

import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Table as Table
import Html exposing (..)
import Html.Attributes exposing (href)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Routes exposing (containerPath)


{-| Run state of a Docker container
See <https://docs.docker.com/engine/api/v1.39/#tag/Container>
-}
type RunState
    = Created
    | Restarting
    | Running
    | Removing
    | Paused
    | Exited
    | Dead


{-| Short information on Docker container, as returned by /containers/json endpoint
-}
type alias DockerContainer =
    { id : String
    , names : List String
    , image : String
    , state : RunState
    , status : String
    , command : String
    }


type DockerContainers
    = DockerContainers (List DockerContainer)


dockerContainerDecoder : Decode.Decoder DockerContainer
dockerContainerDecoder =
    Decode.succeed DockerContainer
        |> required "Id" Decode.string
        |> required "Names" (Decode.list Decode.string)
        |> required "Image" Decode.string
        |> required "State" runStateDecoder
        |> required "Status" Decode.string
        |> required "Command" Decode.string


dockerContainersDecoder : Decode.Decoder DockerContainers
dockerContainersDecoder =
    Decode.map DockerContainers <|
        Decode.list dockerContainerDecoder


runStateDecoder : Decode.Decoder RunState
runStateDecoder =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "created" ->
                        Decode.succeed Created

                    "restarting" ->
                        Decode.succeed Restarting

                    "running" ->
                        Decode.succeed Running

                    "removing" ->
                        Decode.succeed Removing

                    "paused" ->
                        Decode.succeed Paused

                    "exited" ->
                        Decode.succeed Exited

                    "dead" ->
                        Decode.succeed Dead

                    other ->
                        Decode.fail <| "Unknown run state: " ++ other
            )


showRunState : RunState -> String
showRunState runState =
    case runState of
        Created ->
            "created"

        Restarting ->
            "restarting"

        Running ->
            "running"

        Removing ->
            "removing"

        Paused ->
            "paused"

        Exited ->
            "exited"

        Dead ->
            "dead"


getDockerContainers : Cmd Msg
getDockerContainers =
    Http.get
        { url = "/api/docker-engine/?url=/containers/json"
        , expect = Http.expectJson GotDockerContainers dockerContainersDecoder
        }


type alias Model =
    { dockerContainers : Maybe DockerContainers
    , serverError : String
    }


type Msg
    = GetDockerContainers
    | GotDockerContainers (Result Http.Error DockerContainers)


init : ( Model, Cmd Msg )
init =
    ( { dockerContainers = Nothing, serverError = "" }, getDockerContainers )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotDockerContainers (Ok dockerContainers) ->
            ( { model | dockerContainers = Just dockerContainers }, Cmd.none )

        GotDockerContainers (Err error) ->
            ( { model | serverError = "Server error" }, Cmd.none )

        GetDockerContainers ->
            ( model, getDockerContainers )


containerNameOrId : DockerContainer -> String
containerNameOrId container =
    Maybe.withDefault container.id <| List.head container.names


viewContainers : List DockerContainer -> Html Msg
viewContainers containers =
    let
        sortedContainers =
            List.sortBy (\container -> containerNameOrId container) containers
    in
    Table.table
        { options = [ Table.striped, Table.hover ]
        , thead =
            Table.simpleThead
                [ Table.th [] [ text "Name" ]
                , Table.th [] [ text "Image" ]
                , Table.th [] [ text "State" ]
                , Table.th [] [ text "Status" ]
                , Table.th [] [ text "Command" ]
                ]
        , tbody =
            Table.tbody
                []
                (List.map viewContainerRow sortedContainers)
        }


viewContainerRow : DockerContainer -> Table.Row Msg
viewContainerRow container =
    let
        containerName =
            text <| containerNameOrId container
    in
    Table.tr []
        [ Table.td [] [ a [ href <| containerPath container.id ] [ containerName ] ]
        , Table.td [] [ text container.image ]
        , Table.td []
            [ text <| showRunState container.state ]
        , Table.td [] [ text container.status ]
        , Table.td [] [ code [] [ text container.command ] ]
        ]


view : Model -> Html Msg
view model =
    let
        content : Html Msg
        content =
            case model.dockerContainers of
                Just (DockerContainers dockerContainers) ->
                    viewContainers dockerContainers

                Nothing ->
                    text "No containers"
    in
    Grid.row []
        [ Grid.col [ Col.xs11 ]
            [ h1 [] [ text "Containers" ]
            , content
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
