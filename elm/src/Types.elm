module Types exposing
    ( AppMessage
    , AppState
    , MessageSeverity(..)
    , UpdateAppState(..)
    , httpErrorToAppMessage
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


type alias AppMessage =
    { message : String
    , severity : MessageSeverity
    }


type alias AppState =
    { appMessages : List AppMessage
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


type ContainerState
    = Created
    | Restarting
    | Running
    | Paused
    | Exited
    | Dead
