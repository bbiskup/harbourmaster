module Pages.Containers exposing (Model, Msg, init, subscriptions, update, view)

{-| Container list view
-}

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Table as Table
import Bootstrap.Utilities.Spacing as Spacing
import Html exposing (..)
import Html.Attributes exposing (class, href, title)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Routes exposing (containerPath, imagePath)
import String.Extra exposing (ellipsis)
import Util exposing (createEngineApiUrl)


type Msg
    = GetDockerContainers
    | GotDockerContainers (Result Http.Error DockerContainers)
    | ToggleRunStateFilter RunState Bool
    | InvokeAction Action String
    | GotActionResponse Action String (Result Http.Error ActionResponse)


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


{-| Actions on a particular container
-}
type Action
    = Pause
    | Stop
    | Remove


allRunStates : List RunState
allRunStates =
    [ Created, Restarting, Running, Removing, Paused, Exited, Dead ]


{-| Short information on Docker container, as returned by /containers/json endpoint
-}
type alias DockerContainer =
    { id : String
    , names : List String
    , image : String
    , imageId : String
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
        |> required "ImageID" Decode.string
        |> required "State" runStateDecoder
        |> required "Status" Decode.string
        |> required "Command" Decode.string


type alias ActionResponse =
    { message : String }


actionResponseDecoder : Decode.Decoder ActionResponse
actionResponseDecoder =
    Decode.succeed ActionResponse
        |> optional "message" Decode.string ""


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


type alias Model =
    { dockerContainers : Maybe DockerContainers
    , runStates : List RunState
    , serverError : String
    }


{-| Create a run state filter for Docker engine /containers endpoint
-}
createContainersFilter : List RunState -> Encode.Value
createContainersFilter runStates =
    Encode.object
        [ ( "status"
          , Encode.list Encode.string (List.map showRunState runStates)
          )
        ]


getDockerContainers : Model -> Cmd Msg
getDockerContainers model =
    let
        filterQuery : String
        filterQuery =
            createContainersFilter model.runStates
                |> Encode.encode 0
    in
    Http.get
        { url = createEngineApiUrl "/containers/json" (Just <| "filters=" ++ filterQuery)
        , expect = Http.expectJson GotDockerContainers dockerContainersDecoder
        }


invokeAction : String -> Action -> Cmd Msg
invokeAction containerId action =
    let
        actionPart =
            case action of
                Pause ->
                    "pause"

                Stop ->
                    "stop"

                Remove ->
                    "remove"
    in
    Http.post
        { url =
            createEngineApiUrl ("/containers/" ++ containerId ++ "/" ++ actionPart)
                Nothing
        , body = Http.emptyBody
        , expect = Http.expectJson (GotActionResponse action containerId) actionResponseDecoder
        }


init : ( Model, Cmd Msg )
init =
    let
        model =
            { dockerContainers = Nothing
            , runStates = [ Running, Paused, Restarting ]
            , serverError = ""
            }
    in
    ( model
    , getDockerContainers model
    )


addRunState : List RunState -> RunState -> List RunState
addRunState runStates runState =
    if List.member runState runStates then
        runStates

    else
        runState :: runStates


removeRunState : List RunState -> RunState -> List RunState
removeRunState runStates runState =
    List.filter ((/=) runState) runStates


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotDockerContainers (Ok dockerContainers) ->
            ( { model | dockerContainers = Just dockerContainers }
            , Cmd.none
            )

        GotDockerContainers (Err error) ->
            ( { model | serverError = "Server error" }
            , Cmd.none
            )

        GetDockerContainers ->
            ( model, getDockerContainers model )

        ToggleRunStateFilter runState checked ->
            let
                newRunStates : List RunState
                newRunStates =
                    if checked then
                        addRunState model.runStates runState

                    else
                        removeRunState model.runStates runState
            in
            let
                newModel =
                    { model | runStates = newRunStates }
            in
            ( newModel, getDockerContainers newModel )

        InvokeAction action containerId ->
            ( model, invokeAction containerId action )

        GotActionResponse action containerId (Ok _) ->
            ( model, getDockerContainers model )

        GotActionResponse action containerId (Err error) ->
            ( { model | serverError = "Server error" }
            , Cmd.none
            )


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
                , Table.th [] [ text "Actions" ]
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
            containerNameOrId container

        -- the command line could potentially be very long
        commandEllipsis : String
        commandEllipsis =
            ellipsis 30 container.command

        runStateText : String
        runStateText =
            showRunState container.state

        renderActionButton : String -> String -> String -> Button.Option Msg -> Action -> Html Msg
        renderActionButton containerId buttonTitle iconClass buttonKind action =
            Button.button
                [ Button.small
                , buttonKind
                , Button.attrs [ Spacing.ml1 ]
                , Button.onClick (InvokeAction action containerId)
                ]
                [ i
                    [ class ("fas fa-" ++ iconClass)
                    , title buttonTitle
                    ]
                    []
                ]

        pauseButton =
            renderActionButton container.id "Pause" "pause-circle" Button.primary Pause

        stopButton =
            renderActionButton container.id "Stop" "stop-circle" Button.secondary Stop

        removeButton =
            renderActionButton container.id "Remove" "times-circle" Button.danger Remove

        actionButtons =
            if List.any ((==) container.state) [ Created, Restarting, Running ] then
                [ pauseButton, stopButton, removeButton ]

            else if container.state == Paused then
                [ stopButton, removeButton ]

            else
                [ removeButton ]
    in
    Table.tr []
        [ Table.td []
            [ a [ href <| containerPath container.id ] [ text containerName ]
            ]
        , Table.td [ Table.cellAttr <| title container.image ]
            [ a
                [ title containerName
                , href <| imagePath container.imageId
                ]
                [ text <| ellipsis 30 container.image ]
            ]
        , Table.td [ Table.cellAttr <| class ("harbourmaster-runstate-" ++ runStateText) ]
            [ text <| runStateText ]
        , Table.td [] [ text container.status ]
        , Table.td [] [ code [ title container.command ] [ text commandEllipsis ] ]
        , Table.td []
            [ div [] actionButtons
            ]
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

        isChecked : RunState -> Bool
        isChecked runState =
            List.member runState model.runStates

        runStateCheckbox : RunState -> Html Msg
        runStateCheckbox runState =
            Checkbox.checkbox
                [ Checkbox.inline
                , Checkbox.onCheck (ToggleRunStateFilter runState)
                , Checkbox.checked <| isChecked runState
                ]
                (showRunState runState)
    in
    Grid.row []
        [ Grid.col [ Col.xs11 ]
            [ h1 [] [ text "Containers" ]
            , Form.form [] (List.map runStateCheckbox allRunStates)
            , content
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
