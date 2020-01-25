module Main exposing (..)

import Browser
import Browser.Dom exposing (Viewport)
import Browser.Navigation as Nav
import Html exposing (Html, div, span, h1, h2, h3, h4, h4, text, br, a, img, button, i)
import Html.Attributes exposing (type_, value, id, class, href, style, src, alt, rel, target)
import Html.Events exposing (onClick, onInput, onMouseEnter, onMouseLeave)
import Url
import Url.Builder exposing (crossOrigin)
import String exposing (fromInt, append, concat, length)
import Time exposing (..)
import Tuple exposing (first, second)
import List exposing (map, map2)
import Animation exposing (none, block, inline, color, px)
import Animation.Messenger exposing (send)

main =
    Browser.application {
        init = init,
        subscriptions = subscriptions,
        update = update,
        view = view,
        onUrlChange = UrlChanged,
        onUrlRequest = LinkClicked
    }

type Page
    = Hjem
    | Program 
    | Bedrifter
    | Om

type Name
    = Initial
    | Bekk
    | Computas
    | Mnemonic
    | Knowit
    | Dnb

type Msg
    = UrlChanged Url.Url
    | LinkClicked Browser.UrlRequest
    | Tick Time.Posix
    | Animate Animation.Msg
    | Transition
    | LoadNav

type alias Model =
    { 
        key : Nav.Key,
        url : Url.Url,
        page : Page,
        time : Time.Posix,
        titleAnimation : Animation.Messenger.State Msg,
        navbarAnimation : Animation.Messenger.State Msg,
        nav : Bool,
        name : Name
    }

init : () -> Url.Url -> Nav.Key -> (Model, Cmd Msg)
init _ url key =
    ({
        key = key, 
        url = url,
        page = Hjem,
        time = (millisToPosix 0),
        titleAnimation = Animation.interrupt [ Animation.loop [ 
                                                Animation.wait (millisToPosix 4000),
                                                Animation.to [ Animation.opacity 0 ],
                                                Animation.Messenger.send Transition,
                                                Animation.wait (millisToPosix 1500),
                                                Animation.to [ Animation.opacity 1 ]
                                            ] ] (Animation.style [ Animation.opacity 1 ]),
        navbarAnimation = Animation.style [ Animation.top (px -50) ],
        nav = False,
        name = Initial
    },
    Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [Time.every 1000 Tick, Animation.subscription Animate [model.titleAnimation, model.navbarAnimation]]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    (model, Nav.pushUrl model.key (Url.toString url))
                Browser.External href ->
                    (model, Nav.load href) 
        UrlChanged url ->
            case url.path of
                "/hjem" ->
                    ({ model | url = url, page = Hjem }, Cmd.none)
                "/program" ->
                    ({ model | url = url, page = Program }, Cmd.none)
                "/bedrifter" ->
                    ({ model | url = url, page = Bedrifter }, Cmd.none) 
                "/om" ->
                    ({ model | url = url, page = Om }, Cmd.none)
                _ ->
                    ({ model | url = url, page = Hjem }, Cmd.none)
        Tick time ->
            ({ model | time = time }, Cmd.none)
        Animate anim ->
            let (newStyleTitleAnim, titleCmds) = Animation.Messenger.update anim model.titleAnimation
                (newStyleNavbarAnim, navbarCmds) = Animation.Messenger.update anim model.navbarAnimation
            in
               ({ model | titleAnimation = newStyleTitleAnim, navbarAnimation = newStyleNavbarAnim }, (titleCmds))
        Transition ->
            ({ model | name = getNextName model.name }, Cmd.none) 
        LoadNav ->
            if model.nav == False then
                ({ model | nav = True, navbarAnimation = Animation.interrupt [ 
                                                                Animation.to [ Animation.top (px 0) ] ]
                                                                model.navbarAnimation }, Cmd.none)
            else
                ({ model | nav = False, navbarAnimation =  Animation.interrupt [ 
                                                                Animation.to [ Animation.top (px -50) ] ]
                                                                model.navbarAnimation }, Cmd.none)

view : Model -> Browser.Document Msg
view model =
    {
        title = "echo bedriftstur",
        body =
            [
            div [ class "site" ] [
                div [ class "menu" ] [
                    span [ id "hjem" ] [ a [ href "/" ] [ img [ id "logo", alt "logo", src "img/echo-logo-very-wide.png" ] [] ] ],
                    span [ class "navbar" ] [ button [ id "navBtn", onClick LoadNav ] [ i [ id "navBtn-icon", class "fas fa-bars" ] [] ] ],
                    span [ class "menuItem", id "program" ] [ a [ href "/program" ] [ text "Program" ] ],
                    span [ class "menuItem", id "bedrifter" ] [ a [ href "/bedrifter" ] [ text "Bedrifter" ] ],
                    span [ class "menuItem", id "om" ] [ a [ href "/om" ] [ text "Om oss" ] ]
                ],
                div [ id "navbar-content" ] [
                    a [ href "/bedrifter", onClick LoadNav ] [ text "Bedrifter" ],
                    a [ href "/program", onClick LoadNav ] [ text "Program" ],
                    a [ href "/om", onClick LoadNav ] [ text "Om oss" ]
                ],
                div [] (getPages model),
                div [ class "footer" ] [
                    a [ href "https://echo.uib.no" ] [ text "echo - Fagutvalget for Informatikk" ]
                ]
            ]
        ]
    }

getPages : Model -> List (Html Msg)
getPages model =
    case model.page of
        Hjem ->
            [getHjem model False] ++ [getProgram True] ++ [getBedrifter model True] ++ [getOm True]
        Program ->
            [getHjem model True] ++ [getProgram False] ++ [getBedrifter model True] ++ [getOm True]
        Bedrifter ->
            [getHjem model True] ++ [getProgram True] ++ [getBedrifter model False] ++ [getOm True]
        Om ->
            [getHjem model True] ++ [getProgram True] ++ [getBedrifter model True] ++ [getOm False]

getHjem : Model -> Bool -> Html Msg 
getHjem model hide =
    div [ if hide then class "hidden" else class "hjem" ] [
        div [ class "content" ] [

            div [ id "anim" ] [
                h1 [ id "anim-2" ] [ text "echo | " ],
                h1
                    (Animation.render model.titleAnimation ++ [ id "anim-text" ]) [ text (getNameString model.name) ]
            ],
            br [] [],
            div [ class "text" ] [ text "echo har startet en komité for å arrangere bedriftstur til Oslo høsten 2020." ],
            div [ class "text" ] [ text "Formålet med arrangementet er å gjøre våre informatikkstudenter kjent med karrieremulighetene i Oslo." ],
            br [] [],
            div [ class "text" ] [ text "Informasjon kommer fortløpende!" ],
            br [] [],
            br [] []
        ],
        getClock model
    ]

getClock : Model -> Html msg
getClock model =
    div [ class "clock" ] ([
        span [ id "days" ] [ text "D" ],
        span [ id "hours" ] [ text "H" ],
        span [ id "minutes" ] [ text "M" ],
        span [ id "seconds" ] [ text "S" ]
    ] ++ getCountDown model.time)

getProgram : Bool -> Html msg 
getProgram hide =
    div [ if hide then class "hidden" else  class "program" ] [ {-
        div [ id "onsdagMain" ] [ text "onsdag" ],
        div [ id "torsdagMain" ] [ text "torsdag" ],
        div [ id "fredagMain" ] [ text "fredag" ],
        div [ id "time10" ] [ text "10" ],
        div [ id "time11" ] [ text "11" ],
        div [ id "time12" ] [ text "12" ],
        div [ id "time13" ] [ text "13" ],
        div [ id "time14" ] [ text "14" ],
        div [ id "time15" ] [ text "15" ],
        div [ id "time16" ] [ text "16" ],
        div [ id "time17" ] [ text "17" ],
        div [ id "time18" ] [ text "18" ],
        div [ id "time19" ] [ text "19" ],
        div [ id "time20" ] [ text "20" ],
        div [ id "time21" ] [ text "21" ],
        div [ id "time22" ] [ text "22" ],
        div [ class "program-item", id "mnemonic-program" ] [ text "mnemonic" ],
        div [ class "program-item", id "computas-program" ] [ text "computas" ],
        div [ class "program-item", id "dnb-program" ] [ text "dnb" ],
        div [ class "program-item", id "knowit-program" ] [ text "knowit" ],
        div [ class "program-item", id "unk-program" ] [ text "TBD" ],
        div [ class "program-item", id "bekk-program" ] [ text "bekk" ]
    -}
        div [ class "text" ] [ text "Kommer snart!" ]
    ]

getBedrifter : Model -> Bool -> Html Msg 
getBedrifter model hide =
    div [ if hide then class "hidden" else class "logos" ] [
        span [ class "logo-item", id "bekk" ] [ 
            a [ target "_blank", rel "noopener noreferrer", href "https://www.bekk.no" ] [
                img  [ class "bed-logo", src "img/bekk.png", alt "Bekk" ] [] 
            ]
         ],
        span [ class "logo-item", id "mnemonic" ] [
            a [ target "_blank", rel "noopener noreferrer", href "https://www.mnemonic.no" ] [
                img  [ class "bed-logo", src "img/mnemonic.png", alt "Mnemonic" ] [] 
            ]
        ],
        span [ class "logo-item", id "DNB" ] [
            a [ target "_blank", rel "noopener noreferrer", href "https://www.dnb.no" ] [
                img  [ class "bed-logo", src "img/dnb.png", alt "DNB" ] [] 
            ]
        ],
        span [ class "logo-item", id "computas" ] [
            a [ target "_blank", rel "noopener noreferrer", href "https://computas.com" ] [
                img  [ class "bed-logo", src "img/computas.png", alt "Computas" ] [] 
            ]
        ],
        span [ class "logo-item", id "knowit" ] [
            a [ target "_blank", rel "noopener noreferrer", href "https://www.knowit.no" ] [
                img  [ class "bed-logo", src "img/knowit.png", alt "Knowit" ] [] 
            ]
        ],
        span [ class "logo-item", id "TBD" ] [
            a [ target "_blank", rel "noopener noreferrer", href "" ] [
                i [ class "fas fa-hourglass-start" ] []
            ]
        ]
    ]

getOm : Bool -> Html msg 
getOm hide =
    div [ if hide then class "hidden" else class "om" ] [
        div [ id "om-tekst" ] [
            div [ class "text" ] [ text "echo består av 12 demokratisk valgte studenter. Vi er fagutvalget/linjeforeningen for informatikk ved Universitetet i Bergen, men har også et overordnet ansvar for studentsaker som angår det faglige ved instituttet. Vi jobber utelukkende med å gjøre studiehverdagen for oss informatikere bedre og er studentenes stemme opp mot instituttet, fakultetet og arbeidsmarkedet." ], 
            br [] [],
            div [ class "text" ] [ text "Vi representerer studenter under følgende bachelor- og masterprogram: Datateknologi, Data Science, Datasikkerhet, Bioinformatikk, Kognitiv Vitenskap, Informasjonsteknologi, Informatikk (master), Programvareutvikling (master)" ],
            br [] [],
            div [ class "text" ] [ text "Bedriftsturkomitéen består av 3 frivillige studenter." ]
        ],
        div [ id "elias" ] [ img [ class "portrett", src "img/elias.png", alt "elias" ] [] ],
        div [ id "elias-info" ] [
            div [ class "navn" ] [ text "Elias Djupesland" ],
            div [ class "tittel" ] [ text "Leder og bedriftskontakt" ],
            div [ class "mail" ] [ text "elias.djupesland@echo.uib.no" ]
        ],
        div [ id "andreas" ] [ img [ class "portrett", src "img/andreas.png", alt "andreas" ] [] ],
        div [ id "andreas-info" ] [
            div [ class "navn" ] [ text "Andreas Salhus Bakseter" ],
            div [ class "tittel" ] [ text "Web- og transportansvarlig" ],
            div [ class "mail" ] [ text "andreas.bakseter@echo.uib.no" ]
        ],
        div [ id "tuva" ] [ img [ class "portrett", src "img/tuva.png", alt "tuva" ] []],
        div [ id "tuva-info" ] [
            div [ class "navn" ] [ text "Tuva Kvalsøren" ],
            div [ class "tittel" ] [ text "Arrangøransvarlig" ],
            div [ class "mail" ] [ text "tuva.kvalsoren@echo.uib.no" ]
        ]
    ]

getCountDown : Posix -> List (Html msg)
getCountDown dateNow =
    let dateThen = 1598436000 * 1000
        date = dateThen - (posixToMillis dateNow)
    in
        if date == dateThen
        then (map (\x -> div [ class "clockItem", id ("clock" ++ second x) ] [ text (fixNum (fromInt (first x))) ]) [(0,"D"),(0,"H"),(0,"M"),(0,"S")]) 
        else (map (\x -> div [ class "clockItem", id ("clock" ++ second x) ] [ text (fixNum (fromInt (first x))) ]) (calcDate date))

fixNum : String -> String
fixNum str =
    if length str == 1
    then "0" ++ str
    else str

calcDate : Int -> List (Int, String)
calcDate diff =
    let day = diff // (86400 * 1000)
        dayMod = modBy (86400 * 1000) diff
        hour = dayMod // (3600 * 1000)
        hourMod = modBy (3600 * 1000) dayMod
        min = hourMod // (60 * 1000)
        minMod = modBy (60 * 1000) hourMod
        sec = minMod // 1000
    in
        [(day,"D"), (hour,"H"), (min,"M"), (sec,"S")]


loadNav : Model -> Html Msg
loadNav model =
    case model.nav of
        True ->
            div [ id "navbar-content" ] [
                a [ href "/bedrifter", onClick LoadNav ] [ text "Bedrifter" ],
                a [ href "/program", onClick LoadNav ] [ text "Program" ],
                a [ href "/om", onClick LoadNav ] [ text "Om oss" ]
            ]
        False ->
            span [] []

getNextName : Name -> Name
getNextName name =
    case name of
        Initial ->
            Bekk
        Bekk ->
            Computas
        Computas ->
            Mnemonic
        Mnemonic ->
            Knowit
        Knowit ->
            Dnb
        Dnb ->
            Initial

getNameString : Name -> String
getNameString name =
    case name of
        Initial ->
            "bedriftstur"
        Bekk ->
            "Bekk"
        Computas ->
            "Computas"
        Mnemonic ->
            "mnemonic"
        Knowit ->
            "Knowit"
        Dnb ->
            "DNB"
