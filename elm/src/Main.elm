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
import Html.Attributes exposing (class, href, style)
import Json.Encode as Encode
import Pages.Container as Container
import Pages.Containers as Containers
import Pages.Image as Image
import Pages.Images as Images
import Pages.Info as Info
import Pages.Login as Login
import Routes exposing (Route, pathFor)
import Toasty
import Toasty.Defaults
import Types
    exposing
        ( AppState
        , MessageSeverity(..)
        , UpdateAppState
        , messageSeverityToString
        , updateAppState
        )
import Url exposing (Url)
import Util exposing (lastElem)


appTitle : String
appTitle =
    "HarbourMaster"


type alias Model =
    { appState : AppState
    , navKey : Nav.Key
    , route : Route
    , page : Page
    , navbarState : Navbar.State
    , toasties : Toasty.Stack Toasty.Defaults.Toast
    }


type Page
    = PageLogin Login.Model
    | PageInfo Info.Model
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
    | LoginMsg Login.Msg
    | InfoMsg Info.Msg
    | ContainersMsg Containers.Msg
    | ContainerMsg Container.Msg
    | ImagesMsg Images.Msg
    | ImageMsg Image.Msg
    | NavbarMsg Navbar.State
    | ToastyMsg (Toasty.Msg Toasty.Defaults.Toast)


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init () url navKey =
    let
        ( navbarState, navbarCmd ) =
            Navbar.initialState NavbarMsg

        model : Model
        model =
            { appState =
                { appMessages = []
                , auth = Nothing
                }
            , navKey = navKey
            , route = Routes.parseUrl url
            , page = PageNone
            , navbarState = navbarState
            , toasties = Toasty.initialState
            }
    in
    ( model, navbarCmd )
        |> loadCurrentPage


toastyConfig : Toasty.Config msg
toastyConfig =
    let
        containerAttrs =
            [ class "harbourmaster-toasty-list"
            ]
    in
    Toasty.config
        |> Toasty.containerAttrs containerAttrs


loadCurrentPage : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
loadCurrentPage ( model, cmd ) =
    let
        ( page, newCmd ) =
            case model.route of
                Routes.LoginRoute ->
                    let
                        ( pageModel, pageCmd ) =
                            Login.init
                    in
                    ( PageLogin pageModel, Cmd.map LoginMsg pageCmd )

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


sideBar : Model -> Html Msg
sideBar model =
    let
        data =
            [ { link = Routes.loginPath
              , label = "Login"
              , icon = "sign-in-alt"
              }
            , { link = Routes.infoPath
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

        renderToasts : Toasty.Stack Toasty.Defaults.Toast -> Html Msg
        renderToasts toast =
            div [] [ Toasty.view toastyConfig Toasty.Defaults.view ToastyMsg toast ]
    in
    div [ class "harbourmaster-sidebar", h100 ]
        [ b [] [ text appTitle ]
        , ul [ class "harbourmaster-nav-link-list" ] (List.map renderLink data)
        , renderToasts model.toasties
        ]


breadCrumbList : Page -> BreadCrumbs
breadCrumbList page =
    let
        loginTitle =
            "Login"

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
        PageLogin _ ->
            { crumbs = []
            , lastTitle = loginTitle
            }

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
            Breadcrumb.item []
                [ a [ href <| pathFor breadCrumbSpec.route ]
                    [ text <| breadCrumbSpec.title ]
                ]
    in
    Breadcrumb.container
        (List.map createBreadCrumb breadCrumbs.crumbs
            ++ [ Breadcrumb.item [] [ text <| breadCrumbs.lastTitle ] ]
        )


view : Model -> Browser.Document Msg
view model =
    let
        breadCrumbs =
            breadCrumbList model.page
                |> renderBreadCrumbs

        renderAppMessages : Html Msg
        renderAppMessages =
            ul []
                (List.map (\x -> li [] [ text x.message ]) model.appState.appMessages)
    in
    { title = appTitle
    , body =
        [ Grid.containerFluid [ h100 ]
            [ Grid.row [] [ Grid.col [] [ breadCrumbs ] ]
            , Grid.row [ Row.attrs [ h100 ] ]
                [ Grid.col [ Col.xs2, Col.attrs [] ]
                    [ renderAppMessages
                    , sideBar model
                    ]
                , Grid.col [ Col.xs10 ] [ currentPage model ]
                ]
            ]
        ]
    }


currentPage : Model -> Html Msg
currentPage model =
    case model.page of
        PageLogin pageModel ->
            Login.view pageModel
                |> Html.map LoginMsg

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


toastSpecForSeverity : MessageSeverity -> ( String, Int, String -> String -> Toasty.Defaults.Toast )
toastSpecForSeverity severity =
    let
        successDelay =
            3000

        warningDelay =
            10000

        errorDelay =
            60000

        ( delay, toastFunc ) =
            case severity of
                Success ->
                    ( successDelay, Toasty.Defaults.Success )

                Info ->
                    ( successDelay, Toasty.Defaults.Success )

                Warning ->
                    ( warningDelay, Toasty.Defaults.Warning )

                Error ->
                    ( errorDelay, Toasty.Defaults.Error )

                Fatal ->
                    ( errorDelay, Toasty.Defaults.Error )
    in
    ( messageSeverityToString severity, delay, toastFunc )


{-| Convert all pending app messages to Toasty notifications.
App messages are removed after triggering a notification.
-}
convertAppMessagesToToasties : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
convertAppMessagesToToasties ( model, cmd ) =
    case model.appState.appMessages of
        firstAppMessage :: remainingAppMessages ->
            let
                appState =
                    model.appState

                newAppState =
                    { appState | appMessages = remainingAppMessages }

                ( toastTitle, toastDelay, toastFunc ) =
                    toastSpecForSeverity firstAppMessage.severity
            in
            Toasty.addToast (toastyConfig |> Toasty.delay (toFloat toastDelay))
                ToastyMsg
                (toastFunc toastTitle firstAppMessage.message)
                ( { model | appState = newAppState }, cmd )

        [] ->
            ( model, cmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ appState } as model) =
    let
        updateCurrentAppState : UpdateAppState -> AppState
        updateCurrentAppState =
            updateAppState appState

        updated =
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

                ( LoginMsg subMsg, PageLogin pageModel ) ->
                    let
                        ( newPageModel, newCmd, appStateUpdate ) =
                            Login.update subMsg pageModel
                    in
                    ( { model
                        | page = PageLogin newPageModel
                        , appState = updateCurrentAppState appStateUpdate
                      }
                    , Cmd.map LoginMsg newCmd
                    )

                ( LoginMsg subMsg, _ ) ->
                    ( model, Cmd.none )

                ( InfoMsg subMsg, PageInfo pageModel ) ->
                    let
                        ( newPageModel, newCmd, appStateUpdate ) =
                            Info.update subMsg pageModel
                    in
                    ( { model
                        | page = PageInfo newPageModel
                        , appState = updateCurrentAppState appStateUpdate
                      }
                    , Cmd.map InfoMsg newCmd
                    )

                ( InfoMsg subMsg, _ ) ->
                    ( model, Cmd.none )

                ( ContainersMsg subMsg, PageContainers pageModel ) ->
                    let
                        ( newPageModel, newCmd, appStateUpdate ) =
                            Containers.update subMsg pageModel
                    in
                    ( { model
                        | page = PageContainers newPageModel
                        , appState = updateCurrentAppState appStateUpdate
                      }
                    , Cmd.map ContainersMsg newCmd
                    )

                ( ContainersMsg subMsg, _ ) ->
                    ( model, Cmd.none )

                ( ContainerMsg subMsg, PageContainer pageModel ) ->
                    let
                        ( newPageModel, newCmd, appStateUpdate ) =
                            Container.update subMsg pageModel
                    in
                    ( { model
                        | page = PageContainer newPageModel
                        , appState = updateCurrentAppState appStateUpdate
                      }
                    , Cmd.map ContainerMsg newCmd
                    )

                ( ContainerMsg subMsg, _ ) ->
                    ( model, Cmd.none )

                ( ImagesMsg subMsg, PageImages pageModel ) ->
                    let
                        ( newPageModel, newCmd, appStateUpdate ) =
                            Images.update subMsg pageModel
                    in
                    ( { model
                        | page = PageImages newPageModel
                        , appState = updateCurrentAppState appStateUpdate
                      }
                    , Cmd.map ImagesMsg newCmd
                    )

                ( ImagesMsg subMsg, _ ) ->
                    ( model, Cmd.none )

                ( ImageMsg subMsg, PageImage pageModel ) ->
                    let
                        ( newPageModel, newCmd, appStateUpdate ) =
                            Image.update subMsg pageModel
                    in
                    ( { model
                        | page = PageImage newPageModel
                        , appState = updateCurrentAppState appStateUpdate
                      }
                    , Cmd.map ImageMsg newCmd
                    )

                ( ImageMsg subMsg, _ ) ->
                    ( model, Cmd.none )

                ( NavbarMsg state, _ ) ->
                    ( { model | navbarState = state }, Cmd.none )

                ( ToastyMsg subMsg, _ ) ->
                    Toasty.update toastyConfig ToastyMsg subMsg model
    in
    convertAppMessagesToToasties updated


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        PageLogin pageModel ->
            Sub.map LoginMsg (Login.subscriptions pageModel)

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
