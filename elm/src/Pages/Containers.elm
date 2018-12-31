module Pages.Containers exposing (Model, Msg, init, subscriptions, update, view)

{-| Container list view
-}

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Input as Input
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
import Types exposing (ContainerState(..), containerStateToString)
import Util exposing (createEngineApiUrl)


type Msg
    = GetDockerContainers
    | GotDockerContainers (Result Http.Error DockerContainers)
    | ToggleContainerStateFilter ContainerState Bool
    | InvokeAction Action String
    | GotActionResponse Action String (Result Http.Error ActionResponse)
    | SetSearchTerm String


{-| Actions on a particular container
-}
type Action
    = Pause
    | Unpause
    | Stop
    | Remove
    | Restart


allContainerStates : List ContainerState
allContainerStates =
    [ Created, Restarting, Running, Removing, Paused, Exited, Dead ]


{-| Short information on Docker container, as returned by /containers/json endpoint
-}
type alias DockerContainer =
    { id : String
    , names : List String
    , image : String
    , imageId : String
    , state : ContainerState
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
        |> required "State" containerStateDecoder
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


containerStateDecoder : Decode.Decoder ContainerState
containerStateDecoder =
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


type alias Model =
    { dockerContainers : Maybe DockerContainers
    , containerStates : List ContainerState
    , searchTerm : String
    , serverError : String
    }


{-| Create a run state filter for Docker engine /containers endpoint
-}
createContainersFilter : List ContainerState -> Encode.Value
createContainersFilter containerStates =
    Encode.object
        [ ( "status"
          , Encode.list Encode.string (List.map containerStateToString containerStates)
          )
        ]


getDockerContainers : Model -> Cmd Msg
getDockerContainers model =
    let
        filterQuery : String
        filterQuery =
            createContainersFilter model.containerStates
                |> Encode.encode 0
    in
    Http.get
        { url = createEngineApiUrl "/containers/json" (Just <| "filters=" ++ filterQuery)
        , expect = Http.expectJson GotDockerContainers dockerContainersDecoder
        }


invokeAction : String -> Action -> Cmd Msg
invokeAction containerId action =
    let
        ( httpMethod, actionPart ) =
            case action of
                Restart ->
                    ( "POST", "/restart" )

                Pause ->
                    ( "POST", "/pause" )

                Unpause ->
                    ( "POST", "/unpause" )

                Stop ->
                    ( "POST", "/stop" )

                Remove ->
                    ( "DELETE", "" )
    in
    Http.request
        { method = httpMethod
        , headers = []
        , url =
            createEngineApiUrl ("/containers/" ++ containerId ++ actionPart)
                Nothing
        , body = Http.emptyBody
        , expect = Http.expectJson (GotActionResponse action containerId) actionResponseDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


init : ( Model, Cmd Msg )
init =
    let
        model =
            { dockerContainers = Nothing
            , containerStates = [ Running, Paused, Restarting ]
            , searchTerm = ""
            , serverError = ""
            }
    in
    ( model
    , getDockerContainers model
    )


addContainerState : List ContainerState -> ContainerState -> List ContainerState
addContainerState containerStates containerState =
    if List.member containerState containerStates then
        containerStates

    else
        containerState :: containerStates


removeContainerState : List ContainerState -> ContainerState -> List ContainerState
removeContainerState containerStates containerState =
    List.filter ((/=) containerState) containerStates


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

        ToggleContainerStateFilter containerState checked ->
            let
                newContainerStates : List ContainerState
                newContainerStates =
                    if checked then
                        addContainerState model.containerStates containerState

                    else
                        removeContainerState model.containerStates containerState
            in
            let
                newModel =
                    { model | containerStates = newContainerStates }
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

        SetSearchTerm newSearchTerm ->
            ( { model | searchTerm = newSearchTerm }, Cmd.none )


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


renderActionButton : String -> String -> String -> Button.Option Msg -> Action -> Bool -> Html Msg
renderActionButton containerId buttonTitle iconClass buttonKind action isEnabled =
    let
        buttonOptions =
            [ Button.disabled (not isEnabled)
            , Button.small
            , buttonKind
            , Button.attrs [ Spacing.ml1 ]
            , Button.onClick (InvokeAction action containerId)
            ]
    in
    Button.button
        buttonOptions
        [ i
            [ class ("fas fa-" ++ iconClass)
            , title buttonTitle
            ]
            []
        ]


actionButtons : String -> List ( List ContainerState, Bool -> Html Msg )
actionButtons containerId =
    [ ( [ Running, Paused, Exited ]
      , renderActionButton containerId "Restart" "play-circle" Button.warning Restart
      )
    , ( [ Paused ]
      , renderActionButton containerId "Unpause" "arrow-circle-right" Button.success Unpause
      )
    , ( [ Running ]
      , renderActionButton containerId "Pause" "pause-circle" Button.primary Pause
      )
    , ( [ Created, Restarting, Running, Paused ]
      , renderActionButton containerId "Stop" "stop-circle" Button.secondary Stop
      )
    , ( [ Exited, Dead ]
      , renderActionButton containerId "Remove" "times-circle" Button.danger Remove
      )
    ]


viewContainerRow : DockerContainer -> Table.Row Msg
viewContainerRow container =
    let
        containerName =
            containerNameOrId container

        -- the command line could potentially be very long
        commandEllipsis : String
        commandEllipsis =
            ellipsis 30 container.command

        containerStateText : String
        containerStateText =
            containerStateToString container.state

        matchingActionButtons : List (Html Msg)
        matchingActionButtons =
            actionButtons container.id
                |> List.map
                    (\( applicableStates, buttonFn ) ->
                        if List.member container.state applicableStates then
                            buttonFn True

                        else
                            -- disable button
                            buttonFn False
                    )
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
        , Table.td [ Table.cellAttr <| class ("harbourmaster-runstate-" ++ containerStateText) ]
            [ text <| containerStateText ]
        , Table.td [] [ text container.status ]
        , Table.td [] [ code [ title container.command ] [ text commandEllipsis ] ]
        , Table.td []
            [ div [] matchingActionButtons
            ]
        ]


filterContainers : List DockerContainer -> String -> List DockerContainer
filterContainers dockerContainers searchTerm =
    if searchTerm == "" then
        dockerContainers

    else
        List.filter
            (\container ->
                String.contains searchTerm (containerNameOrId container)
                    || String.contains searchTerm container.image
            )
            dockerContainers


view : Model -> Html Msg
view model =
    let
        content : Html Msg
        content =
            case model.dockerContainers of
                Just (DockerContainers dockerContainers) ->
                    viewContainers <| filterContainers dockerContainers model.searchTerm

                Nothing ->
                    text "No containers"

        isChecked : ContainerState -> Bool
        isChecked containerState =
            List.member containerState model.containerStates

        containerStateCheckbox : ContainerState -> Html Msg
        containerStateCheckbox containerState =
            Checkbox.checkbox
                [ Checkbox.inline
                , Checkbox.onCheck (ToggleContainerStateFilter containerState)
                , Checkbox.checked <| isChecked containerState
                ]
                (containerStateToString containerState)

        filterInput =
            Input.text
                [ Input.attrs [ title "Filter by container name" ]
                , Input.placeholder "Search term"
                , Input.onInput SetSearchTerm
                ]
    in
    Grid.row []
        [ Grid.col [ Col.xs11 ]
            [ h1 [] [ text "Containers" ]
            , Form.formInline [ class "harbourmaster-table-form" ]
                (List.map containerStateCheckbox allContainerStates ++ [ filterInput ])
            , content
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
