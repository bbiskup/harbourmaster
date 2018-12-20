module HarbourMaster exposing (main)

import Browser
import Html exposing (..)


type alias Model =
    { dummy : String
    }


type Msg
    = DockerInfo


initialModel =
    { dummy = "Dummy"
    }


initialCmd : Cmd Msg
initialCmd =
    Cmd.none


view : Model -> Html Msg
view model =
    div [] [ text "App" ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        _ ->
            ( model, Cmd.none )


init : () -> ( Model, Cmd Msg )
init flags =
    ( initialModel, initialCmd )


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }
