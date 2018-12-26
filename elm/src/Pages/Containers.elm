module Pages.Containers exposing (Model, Msg, init, subscriptions, update)

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


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
