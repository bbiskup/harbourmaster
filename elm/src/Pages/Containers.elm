module Pages.Containers exposing (Model, Msg, init, subscriptions, update, view)

import Html exposing (..)
import Http


type alias Model =
    {}


init : ( Model, Cmd Msg )
init =
    ( {}, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



-- TODO


type alias DockerContainer =
    { id : String }


type Msg
    = GetDockerContainers
    | GotDockerContainers (Result Http.Error (List DockerContainer))


view : Model -> Html Msg
view model =
    div [] [ text "Containers page" ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
