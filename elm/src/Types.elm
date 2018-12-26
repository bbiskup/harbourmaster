module Types exposing (AppState)

{-| Application state shared between pages
-}


type alias AppState =
    { dummyGlobalState : String
    }


type ContainerState
    = Created
    | Restarting
    | Running
    | Paused
    | Exited
    | Dead
