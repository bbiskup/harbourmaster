module Types exposing
    ( AppMessage
    , AppState
    , Auth
    , ContainerState(..)
    , MessageSeverity(..)
    , UpdateAppState(..)
    , containerStateToString
    , httpErrorToAppMessage
    , messageSeverityToString
    , updateAppState
    )

import Http
import Util exposing (httpErrorToString)


{-| State shared between all pages.
Based on the [Taco idiom](https://github.com/ohanhi/elm-taco).
-}
type MessageSeverity
    = Success
    | Info
    | Warning
    | Error
    | Fatal


messageSeverityToString : MessageSeverity -> String
messageSeverityToString severity =
    case severity of
        Success ->
            "Success"

        Info ->
            "Info"

        Warning ->
            "Warning"

        Error ->
            "Error"

        Fatal ->
            "Fatal"


type alias AppMessage =
    { message : String
    , severity : MessageSeverity
    }


{-| Information about logged in user
-}
type alias Auth =
    { sessionID : String
    }


type alias AppState =
    { appMessages : List AppMessage
    , auth : Maybe Auth
    }


{-| Instructions to update the shared application state.
Rather than returning a modified state directly,
each page may emit such an instruction.
-}
type UpdateAppState
    = AddAppMessage AppMessage
    | NoOp


updateAppState : AppState -> UpdateAppState -> AppState
updateAppState appState updateInstruction =
    case updateInstruction of
        AddAppMessage appMessage ->
            { appState | appMessages = appMessage :: appState.appMessages }

        NoOp ->
            appState


httpErrorToAppMessage : Http.Error -> AppMessage
httpErrorToAppMessage err =
    AppMessage (httpErrorToString err) Error


{-| Run state of a Docker container
See <https://docs.docker.com/engine/api/v1.39/#tag/Container>
-}
type ContainerState
    = Created
    | Restarting
    | Running
    | Removing
    | Paused
    | Exited
    | Dead


containerStateToString : ContainerState -> String
containerStateToString containerState =
    case containerState of
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
