module Pages.Images exposing (Model, Msg, init, subscriptions, update, view)

import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Table as Table
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (checked, href, title, type_)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Routes exposing (imagesPath)
import String.Extra exposing (ellipsis)
import Util exposing (bytesToMiB)



{- Short information on Docker image, as returned by /images/json endpoint -}


type alias DockerImage =
    { id : String
    , labels : Dict String String
    , size : Int
    }


type DockerImages
    = DockerImages (List DockerImage)


dockerImageDecoder : Decode.Decoder DockerImage
dockerImageDecoder =
    Decode.succeed DockerImage
        |> required "Id" Decode.string
        |> optional "Labels" (Decode.dict Decode.string) (Dict.fromList [])
        |> required "Size" Decode.int


dockerImagesDecoder : Decode.Decoder DockerImages
dockerImagesDecoder =
    Decode.map DockerImages <|
        Decode.list dockerImageDecoder


getDockerImages : Cmd Msg
getDockerImages =
    Http.get
        { url = "/api/docker-engine/?url=/images/json"
        , expect = Http.expectJson GotDockerImages dockerImagesDecoder
        }


type alias Model =
    { dockerImages : Maybe DockerImages
    , serverError : String
    , filterUnnamedImages : Bool
    }


type Msg
    = GetDockerImages
    | GotDockerImages (Result Http.Error DockerImages)
    | ToggleFilterUnnamedImages


init : ( Model, Cmd Msg )
init =
    ( { dockerImages = Nothing, serverError = "", filterUnnamedImages = True }, getDockerImages )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotDockerImages (Ok dockerImages) ->
            ( { model | dockerImages = Just dockerImages }
            , Cmd.none
            )

        GotDockerImages (Err error) ->
            ( { model | serverError = "Server error" }
            , Cmd.none
            )

        GetDockerImages ->
            ( model, getDockerImages )

        ToggleFilterUnnamedImages ->
            ( { model | filterUnnamedImages = not model.filterUnnamedImages }
            , getDockerImages
            )


imageNameOrId : DockerImage -> String
imageNameOrId image =
    Maybe.withDefault image.id <| Dict.get "name" image.labels


viewImages : List DockerImage -> Bool -> Html Msg
viewImages images filterUnnamedImages =
    let
        filteredImages =
            if filterUnnamedImages then
                List.filter (\image -> not <| String.startsWith "sha256:" <| imageNameOrId image) images

            else
                images

        sortedImages =
            List.sortBy imageNameOrId filteredImages
    in
    Table.table
        { options = [ Table.striped, Table.hover ]
        , thead =
            Table.simpleThead
                [ Table.th [] [ text "Name" ]
                , Table.th [] [ text "Size (MiB)" ]
                ]
        , tbody =
            Table.tbody
                []
                (List.map viewImageRow sortedImages)
        }


viewImageRow : DockerImage -> Table.Row Msg
viewImageRow image =
    let
        imageName : String
        imageName =
            imageNameOrId image
                |> ellipsis 40

        sizeStr =
            image.size
                |> bytesToMiB
                |> String.fromInt
    in
    Table.tr []
        -- TODO supply full link to image in href
        [ Table.td [] [ a [ title imageName, href <| image.id ] [ text imageName ] ]
        , Table.td [] [ text sizeStr ]
        ]


view : Model -> Html Msg
view model =
    let
        content : Html Msg
        content =
            case model.dockerImages of
                Just (DockerImages dockerImages) ->
                    viewImages dockerImages model.filterUnnamedImages

                Nothing ->
                    text "No images"
    in
    Grid.row []
        [ Grid.col [ Col.xs11 ]
            [ h1 [] [ text "Images" ]
            , label []
                [ input
                    [ type_ "checkbox"
                    , onClick ToggleFilterUnnamedImages
                    , checked model.filterUnnamedImages
                    ]
                    []
                , text "Filter unnamed images"
                ]
            , br
                []
                []
            , content
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
