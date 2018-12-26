module Pages.Containers exposing (Model, Msg, init, subscriptions, update, view)

import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Html exposing (..)
import Html.Attributes exposing (href)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)



{- Short information on Docker container, as returned by /containers/json endpoint -}


type alias DockerContainer =
    { id : String
    , names : List String
    , image : String
    }


type DockerContainers
    = DockerContainers (List DockerContainer)


dockerContainerDecoder : Decode.Decoder DockerContainer
dockerContainerDecoder =
    Decode.succeed DockerContainer
        |> required "Id" Decode.string
        |> required "Names" (Decode.list Decode.string)
        |> required "Image" Decode.string


dockerContainersDecoder : Decode.Decoder DockerContainers
dockerContainersDecoder =
    Decode.map DockerContainers <|
        Decode.list dockerContainerDecoder


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


viewContainer : DockerContainer -> Card.Config msg
viewContainer container =
    Card.config [ Card.outlinePrimary ]
        |> Card.headerH4 [] [ text <| containerNameOrId container ]
        |> Card.block []
            [ Block.text [] [ text container.image ]
            ]


view : Model -> Html Msg
view model =
    let
        content : Html Msg
        content =
            case model.dockerContainers of
                Just (DockerContainers dockerContainers) ->
                    Card.columns <| List.map viewContainer dockerContainers

                Nothing ->
                    text "No containers"
    in
    Grid.row []
        [ Grid.col [ Col.xs11 ] [ content ] ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
