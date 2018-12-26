module Main exposing (main)

import Browser exposing (UrlRequest)
import Browser.Navigation as Nav
import Html exposing (..)
import Pages.Containers as Containers
import Pages.Info as Info
import Routes exposing (Route)
import Types exposing (AppState)
import Url exposing (Url)


type alias Model =
    { appTitle : String
    , navKey : Nav.Key
    , route : Route
    , page : Page
    }


type Page
    = PageInfo Info.Model
    | PageContainers Containers.Model
    | PageNone


type Msg
    = OnUrlChange Url
    | OnUrlRequest UrlRequest
    | InfoMsg Info.Msg
    | ContainersMsg Containers.Msg


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init () url navKey =
    let
        model =
            { appTitle = "HarbourMaster"
            , navKey = navKey
            , route = Routes.parseUrl url
            , page = PageNone
            }
    in
    ( model, Cmd.none )
        |> loadCurrentPage


loadCurrentPage : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
loadCurrentPage ( model, cmd ) =
    let
        ( page, newCmd ) =
            case model.route of
                Routes.InfoRoute ->
                    let
                        ( pageModel, pageCmd ) =
                            Info.init
                    in
                    ( PageInfo pageModel, Cmd.map InfoMsg pageCmd )

                Routes.ContainersRoute ->
                    let
                        ( pageModel, pageCmd ) =
                            Containers.init
                    in
                    ( PageContainers pageModel, Cmd.map ContainersMsg pageCmd )

                Routes.NotFoundRoute ->
                    ( PageNone, Cmd.none )
    in
    ( { model | page = page }, Cmd.batch [ cmd, newCmd ] )


view : Model -> Browser.Document Msg
view model =
    { title = model.appTitle
    , body = [ currentPage model ]
    }


currentPage : Model -> Html Msg
currentPage model =
    case model.page of
        PageInfo pageModel ->
            div [] [ text "Info page" ]

        PageContainers pageModel ->
            div [] [ text "Containers page" ]

        PageNone ->
            notFoundView


notFoundView : Html Msg
notFoundView =
    div [] [ text "not found" ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( OnUrlRequest urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.navKey (Url.toString url) )

                Browser.External url ->
                    ( model, Nav.load url )

        ( OnUrlChange url, _ ) ->
            let
                newRoute =
                    Routes.parseUrl url
            in
            ( { model | route = newRoute }, Cmd.none )
                |> loadCurrentPage

        ( InfoMsg subMsg, PageInfo pageModel ) ->
            let
                ( newPageModel, newCmd ) =
                    Info.update subMsg pageModel
            in
            ( { model | page = PageInfo newPageModel }, Cmd.map InfoMsg newCmd )

        ( InfoMsg subMsg, _ ) ->
            ( model, Cmd.none )

        ( ContainersMsg subMsg, PageContainers pageModel ) ->
            let
                ( newPageModel, newCmd ) =
                    Containers.update subMsg pageModel
            in
            ( { model | page = PageContainers newPageModel }, Cmd.map ContainersMsg newCmd )

        ( ContainersMsg subMsg, _ ) ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        PageInfo pageModel ->
            Sub.map InfoMsg (Info.subscriptions pageModel)

        PageContainers pageModel ->
            Sub.map ContainersMsg (Containers.subscriptions pageModel)

        PageNone ->
            Sub.none


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = OnUrlRequest
        , onUrlChange = OnUrlChange
        }
