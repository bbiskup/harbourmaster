module Main exposing (main)

{-| SPA routing (see e.g. <https://github.com/sporto/elm-tutorial-app>)
-}

import Bootstrap.Breadcrumb as Breadcrumb
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.Navbar as Navbar
import Bootstrap.Utilities.Size exposing (h100)
import Browser exposing (UrlRequest)
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (class, href)
import Json.Encode as Encode
import Pages.Container as Container
import Pages.Containers as Containers
import Pages.Image as Image
import Pages.Images as Images
import Pages.Info as Info
import Routes exposing (Route, pathFor)
import Types exposing (AppState)
import Url exposing (Url)
import Util exposing (lastElem)


appTitle : String
appTitle =
    "HarbourMaster"


type alias Model =
    { navKey : Nav.Key
    , route : Route
    , page : Page
    , navbarState : Navbar.State
    }


type Page
    = PageInfo Info.Model
    | PageContainers Containers.Model
    | PageContainer Container.Model
    | PageImages Images.Model
    | PageImage Image.Model
    | PageNone


type alias BreadCrumbSpec =
    { route : Route
    , title : String
    }


type alias BreadCrumbs =
    { crumbs : List BreadCrumbSpec
    , lastTitle : String
    }


type Msg
    = OnUrlChange Url
    | OnUrlRequest UrlRequest
    | InfoMsg Info.Msg
    | ContainersMsg Containers.Msg
    | ContainerMsg Container.Msg
    | ImagesMsg Images.Msg
    | ImageMsg Image.Msg
    | NavbarMsg Navbar.State


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init () url navKey =
    let
        ( navbarState, navbarCmd ) =
            Navbar.initialState NavbarMsg

        model =
            { navKey = navKey
            , route = Routes.parseUrl url
            , page = PageNone
            , navbarState = navbarState
            }
    in
    ( model, navbarCmd )
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

                Routes.ContainerRoute id ->
                    let
                        ( pageModel, pageCmd ) =
                            Container.init id
                    in
                    ( PageContainer pageModel, Cmd.map ContainerMsg pageCmd )

                Routes.ImagesRoute ->
                    let
                        ( pageModel, pageCmd ) =
                            Images.init
                    in
                    ( PageImages pageModel, Cmd.map ImagesMsg pageCmd )

                Routes.ImageRoute id ->
                    let
                        ( pageModel, pageCmd ) =
                            Image.init id
                    in
                    ( PageImage pageModel, Cmd.map ImageMsg pageCmd )

                Routes.NotFoundRoute ->
                    ( PageNone, Cmd.none )
    in
    ( { model | page = page }, Cmd.batch [ cmd, newCmd ] )


sideBar : Html Msg
sideBar =
    let
        data =
            [ { link = Routes.infoPath
              , label = "Info"
              , icon = "info-circle"
              }
            , { link = Routes.imagesPath
              , label = "Images"
              , icon = "image"
              }
            , { link = Routes.containersPath
              , label = "Containers"
              , icon = "box"
              }
            ]

        renderLink linkData =
            li []
                [ i [ class <| "harbourmaster-nav-link-icon fas fa-" ++ linkData.icon ] []
                , a [ href linkData.link, class "harbourmaster-nav-link" ] [ text linkData.label ]
                ]
    in
    div [ class "harbourmaster-sidebar", h100 ]
        [ b [] [ text appTitle ]
        , ul [ class "harbourmaster-nav-link-list" ] (List.map renderLink data)
        ]


breadCrumbList : Page -> BreadCrumbs
breadCrumbList page =
    let
        imagesTitle =
            "Images"

        imageTitle =
            "Image"

        containersTitle =
            "Containers"

        containerTitle =
            "Container"
    in
    case page of
        PageInfo _ ->
            { crumbs = []
            , lastTitle = "Info"
            }

        PageImages _ ->
            { crumbs = []
            , lastTitle = imagesTitle
            }

        PageImage _ ->
            { crumbs =
                [ { route = Routes.ImagesRoute, title = imagesTitle }
                ]
            , lastTitle = imageTitle
            }

        PageContainers _ ->
            { crumbs = []
            , lastTitle = containersTitle
            }

        PageContainer _ ->
            { crumbs =
                [ { route = Routes.ContainersRoute, title = containersTitle }
                ]
            , lastTitle = containerTitle
            }

        -- most pages are at the top level, so no breadcrumbs are needed
        PageNone ->
            { crumbs = [], lastTitle = "" }


renderBreadCrumbs : BreadCrumbs -> Html Msg
renderBreadCrumbs breadCrumbs =
    let
        createBreadCrumb : BreadCrumbSpec -> Breadcrumb.Item msg
        createBreadCrumb breadCrumbSpec =
            Breadcrumb.item [] [ a [ href <| pathFor breadCrumbSpec.route ] [ text <| breadCrumbSpec.title ] ]
    in
    Breadcrumb.container
        (List.map createBreadCrumb breadCrumbs.crumbs ++ [ Breadcrumb.item [] [ text <| breadCrumbs.lastTitle ] ])


view : Model -> Browser.Document Msg
view model =
    let
        breadCrumbs =
            breadCrumbList model.page
                |> renderBreadCrumbs
    in
    { title = appTitle
    , body =
        [ Grid.containerFluid [ h100 ]
            [ Grid.row [] [ Grid.col [] [ breadCrumbs ] ]
            , Grid.row [ Row.attrs [ h100 ] ]
                [ Grid.col [ Col.xs2, Col.attrs [] ] [ sideBar ]
                , Grid.col [ Col.xs10 ] [ currentPage model ]
                ]
            ]
        ]
    }


currentPage : Model -> Html Msg
currentPage model =
    case model.page of
        PageInfo pageModel ->
            Info.view pageModel
                |> Html.map InfoMsg

        PageContainers pageModel ->
            Containers.view pageModel
                |> Html.map ContainersMsg

        PageContainer pageModel ->
            Container.view pageModel
                |> Html.map ContainerMsg

        PageImages pageModel ->
            Images.view pageModel
                |> Html.map ImagesMsg

        PageImage pageModel ->
            Image.view pageModel
                |> Html.map ImageMsg

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
            ( { model | page = PageInfo newPageModel }
            , Cmd.map InfoMsg newCmd
            )

        ( InfoMsg subMsg, _ ) ->
            ( model, Cmd.none )

        ( ContainersMsg subMsg, PageContainers pageModel ) ->
            let
                ( newPageModel, newCmd ) =
                    Containers.update subMsg pageModel
            in
            ( { model | page = PageContainers newPageModel }
            , Cmd.map ContainersMsg newCmd
            )

        ( ContainersMsg subMsg, _ ) ->
            ( model, Cmd.none )

        ( ContainerMsg subMsg, PageContainer pageModel ) ->
            let
                ( newPageModel, newCmd ) =
                    Container.update subMsg pageModel
            in
            ( { model | page = PageContainer newPageModel }
            , Cmd.map ContainerMsg newCmd
            )

        ( ContainerMsg subMsg, _ ) ->
            ( model, Cmd.none )

        ( ImagesMsg subMsg, PageImages pageModel ) ->
            let
                ( newPageModel, newCmd ) =
                    Images.update subMsg pageModel
            in
            ( { model | page = PageImages newPageModel }
            , Cmd.map ImagesMsg newCmd
            )

        ( ImagesMsg subMsg, _ ) ->
            ( model, Cmd.none )

        ( ImageMsg subMsg, PageImage pageModel ) ->
            let
                ( newPageModel, newCmd ) =
                    Image.update subMsg pageModel
            in
            ( { model | page = PageImage newPageModel }
            , Cmd.map ImageMsg newCmd
            )

        ( ImageMsg subMsg, _ ) ->
            ( model, Cmd.none )

        ( NavbarMsg state, _ ) ->
            ( { model | navbarState = state }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        PageInfo pageModel ->
            Sub.map InfoMsg (Info.subscriptions pageModel)

        PageContainers pageModel ->
            Sub.map ContainersMsg (Containers.subscriptions pageModel)

        PageContainer pageModel ->
            Sub.map ContainerMsg (Container.subscriptions pageModel)

        PageImages pageModel ->
            Sub.map ImagesMsg (Images.subscriptions pageModel)

        PageImage pageModel ->
            Sub.map ImageMsg (Image.subscriptions pageModel)

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
