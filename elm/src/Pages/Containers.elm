module Pages.Containers exposing (Model, Msg, init, subscriptions, update, view)

import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Table as Table
import Html exposing (..)
import Html.Attributes exposing (href)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Routes exposing (containerPath)



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


viewContainers : List DockerContainer -> Html Msg
viewContainers containers =
    Table.table
        { options = [ Table.striped, Table.hover ]
        , thead =
            Table.simpleThead
                [ Table.th [] [ text "Name" ]
                , Table.th [] [ text "Image" ]
                ]
        , tbody =
            Table.tbody
                []
                (List.map viewContainerRow containers)
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
