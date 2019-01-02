module Main exposing (main)

import Api
    exposing
        ( addBillToProject
        , addMemberToProject
        , createProject
        , deleteProjectBill
        , deleteProjectMember
        , editProjectBill
        , editProjectMember
        , fetchProjectBills
        , fetchProjectInfo
        , reactivateProjectMember
        )
import BillBoard exposing (billBoardView)
import Browser exposing (Document)
import Footer exposing (footerView)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Locales exposing (getString)
import Login exposing (loginView)
import Modal exposing (handleModal)
import NavBar exposing (navBarView, simpleNavBarView)
import Round exposing (round)
import SideBar exposing (sideBarView)
import Slug
import Types exposing (..)
import Utils exposing (sortByLowerCaseName)


init : () -> ( Model, Cmd Msg )
init flags =
    let
        auth =
            Basic "demo" "demo"
    in
    ( { auth = auth
      , locale = FR
      , project = Nothing
      , fields =
            { newMember = ""
            , newMemberWeight = ""
            , loginProjectID = ""
            , loginPassword = ""
            , newProjectName = ""
            , newProjectPassword = ""
            , newProjectEmail = ""
            , newProjectError = Nothing
            }
      , modal = BillModal Nothing
      , selectedBill = Just emptyBill
      }
    , fetchProjectInfo auth "demo"
    )


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


setNewMemberName : String -> Fields -> Fields
setNewMemberName newMember fields =
    { fields | newMember = newMember }


setNewMemberWeight : String -> Fields -> Fields
setNewMemberWeight newWeight fields =
    { fields | newMemberWeight = newWeight }


setNewProjectName : String -> Fields -> Fields
setNewProjectName value fields =
    { fields | newProjectName = value, newProjectError = Nothing }


setNewProjectPassword : String -> Fields -> Fields
setNewProjectPassword value fields =
    { fields | newProjectPassword = value }


setNewProjectEmail : String -> Fields -> Fields
setNewProjectEmail value fields =
    { fields | newProjectEmail = value }


setNewProjectError : String -> Fields -> Fields
setNewProjectError value fields =
    { fields | newProjectError = Just value }


setLoginProjectID : String -> Fields -> Fields
setLoginProjectID value fields =
    { fields | loginProjectID = value }


setLoginPassword : String -> Fields -> Fields
setLoginPassword value fields =
    { fields | loginPassword = value }


setMemberToProject : Member -> Project -> Project
setMemberToProject member project =
    { project | members = sortByLowerCaseName (project.members ++ [ member ]) }


setEditedProjectMember : Member -> Project -> Project
setEditedProjectMember member project =
    let
        members =
            List.filter (\m -> m.id /= member.id) project.members
                |> List.append [ member ]
                |> sortByLowerCaseName
    in
    { project | members = members }


setDeletedProjectMember : Int -> Project -> Project
setDeletedProjectMember member_id project =
    let
        selectedMember =
            List.filter (\m -> m.id == member_id) project.members |> List.head
    in
    case selectedMember of
        Nothing ->
            project

        Just member ->
            let
                newMember =
                    { member | activated = False }

                members =
                    List.filter (\m -> m.id /= member.id) project.members
                        |> List.append [ newMember ]
                        |> sortByLowerCaseName
            in
            { project | members = members }


setDeletedProjectBill : Int -> Project -> Project
setDeletedProjectBill bill_id project =
    let
        bills =
            List.filter (\b -> b.id /= bill_id) project.bills
    in
    { project | bills = bills }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewMemberName value ->
            let
                fields =
                    setNewMemberName value model.fields
            in
            ( { model | fields = fields }, Cmd.none )

        NewMemberWeight value ->
            let
                fields =
                    setNewMemberWeight value model.fields
            in
            ( { model | fields = fields }, Cmd.none )

        AddMember ->
            case model.project of
                Just project ->
                    ( model, addMemberToProject model.auth model.fields.newMember )

                Nothing ->
                    ( model, Cmd.none )

        TriggerAddBill bill ->
            case model.project of
                Just project ->
                    ( model
                    , addBillToProject model.auth bill
                    )

                Nothing ->
                    ( model, Cmd.none )

        TriggerEditBill bill ->
            case model.project of
                Just project ->
                    ( model
                    , editProjectBill model.auth bill
                    )

                Nothing ->
                    ( model, Cmd.none )

        TriggerEditMember member_id ->
            case model.project of
                Just project ->
                    ( model
                    , editProjectMember model.auth
                        { id = member_id
                        , name = model.fields.newMember
                        , weight = Maybe.withDefault 1 <| String.toInt model.fields.newMemberWeight
                        , activated = True
                        }
                    )

                Nothing ->
                    ( model, Cmd.none )

        ReactivateMember member ->
            case model.project of
                Just project ->
                    ( model
                    , reactivateProjectMember model.auth member
                    )

                Nothing ->
                    ( model, Cmd.none )

        MemberAdded (Ok id) ->
            case model.project of
                Just project ->
                    let
                        fields =
                            setNewMemberName "" model.fields

                        member =
                            Member id model.fields.newMember 1 True

                        newProject =
                            setMemberToProject member project
                    in
                    ( { model
                        | project = Just newProject
                        , fields = fields
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        MemberAdded (Err err) ->
            let
                _ =
                    Debug.log "Error while adding the member" err
            in
            ( model, Cmd.none )

        MemberEdited (Ok member) ->
            case model.project of
                Just project ->
                    let
                        fields =
                            model.fields |> setNewMemberName "" |> setNewMemberWeight ""

                        newProject =
                            setEditedProjectMember member project
                    in
                    ( { model
                        | project = Just newProject
                        , fields = fields
                        , modal = Hidden
                      }
                    , fetchProjectBills model.auth project.name
                    )

                Nothing ->
                    ( { model | modal = Hidden }, Cmd.none )

        MemberEdited (Err err) ->
            let
                _ =
                    Debug.log "Error while editing the member" err
            in
            ( { model | modal = Hidden }, Cmd.none )

        MemberDeleted member_id (Ok _) ->
            case model.project of
                Just project ->
                    let
                        newProject =
                            setDeletedProjectMember member_id project
                    in
                    ( { model
                        | project = Just newProject
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        MemberDeleted member_id (Err err) ->
            let
                _ =
                    Debug.log ("Error while removing the member " ++ String.fromInt member_id) err
            in
            ( model, Cmd.none )

        NewProjectName value ->
            let
                fields =
                    setNewProjectName value model.fields
            in
            ( { model | fields = fields }, Cmd.none )

        NewProjectPassword value ->
            let
                fields =
                    setNewProjectPassword value model.fields
            in
            ( { model | fields = fields }, Cmd.none )

        NewProjectEmail value ->
            let
                fields =
                    setNewProjectEmail value model.fields
            in
            ( { model | fields = fields }, Cmd.none )

        CreateProject ->
            let
                projectID =
                    model.fields.newProjectName

                slug =
                    Slug.generate projectID

                password =
                    model.fields.newProjectPassword

                email =
                    model.fields.newProjectEmail
            in
            case slug of
                Just _ ->
                    let
                        fields =
                            model.fields |> setNewProjectName "" |> setNewProjectPassword "" |> setNewProjectEmail ""
                    in
                    ( { model | fields = fields, auth = Basic projectID password }
                    , createProject projectID password email
                    )

                Nothing ->
                    let
                        _ =
                            Debug.log "Invalid ProjectName" projectID

                        fields =
                            model.fields
                                |> setNewProjectError ("Invalid project name: " ++ projectID)
                    in
                    ( { model | fields = fields }, Cmd.none )

        ProjectCreated (Ok projectID) ->
            let
                password =
                    case model.auth of
                        Basic user pass ->
                            pass

                        Unauthenticated ->
                            ""

                auth =
                    Basic projectID password
            in
            ( { model | auth = auth }
            , fetchProjectInfo auth projectID
            )

        ProjectCreated (Err err) ->
            let
                _ =
                    Debug.log "Error while creating the project" err
            in
            ( model, Cmd.none )

        LoginProjectID value ->
            let
                fields =
                    setLoginProjectID value model.fields
            in
            ( { model | fields = fields }, Cmd.none )

        LoginPassword value ->
            let
                fields =
                    setLoginPassword value model.fields
            in
            ( { model | fields = fields }, Cmd.none )

        Login ->
            let
                projectID =
                    model.fields.loginProjectID

                password =
                    model.fields.loginPassword

                fields =
                    model.fields |> setLoginProjectID "" |> setLoginPassword ""

                auth =
                    Basic projectID password
            in
            ( { model | fields = fields, auth = auth }
            , fetchProjectInfo auth projectID
            )

        DemoLogin ->
            let
                fields =
                    model.fields |> setLoginProjectID "" |> setLoginPassword ""

                auth =
                    Basic "demo" "demo"
            in
            ( { model | fields = fields, auth = auth }
            , fetchProjectInfo auth "demo"
            )

        LogoutUser ->
            ( { model | auth = Unauthenticated }, Cmd.none )

        ProjectFetched (Ok project) ->
            let
                projectId =
                    case model.auth of
                        Basic user pass ->
                            user

                        Unauthenticated ->
                            ""
            in
            ( { model
                | project = Just project
              }
            , fetchProjectBills model.auth projectId
            )

        ProjectFetched (Err err) ->
            let
                _ =
                    Debug.log "Error while loading the project" err
            in
            ( { model | auth = Unauthenticated }, Cmd.none )

        BillsFetched (Ok bills) ->
            case model.project of
                Just project ->
                    let
                        newProject =
                            { project | bills = bills }
                    in
                    ( { model
                        | project = Just newProject
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        BillsFetched (Err err) ->
            let
                _ =
                    Debug.log "Error while loading the project bills" err
            in
            ( { model | auth = Unauthenticated }, Cmd.none )

        ChangeLocale locale ->
            ( { model | locale = locale }, Cmd.none )

        EditModal modal_type ->
            case model.project of
                Just project ->
                    case modal_type of
                        MemberModal member_id ->
                            let
                                getMember =
                                    List.filter (\m -> m.id == member_id) project.members |> List.head
                            in
                            case getMember of
                                Just member ->
                                    ( { model
                                        | modal = modal_type
                                        , fields =
                                            model.fields
                                                |> setNewMemberName member.name
                                                |> setNewMemberWeight (String.fromInt member.weight)
                                      }
                                    , Cmd.none
                                    )

                                Nothing ->
                                    ( model, Cmd.none )

                        BillModal maybeBill ->
                            case maybeBill of
                                Nothing ->
                                    -- Add a new bill
                                    ( { model
                                        | modal = modal_type
                                        , selectedBill = Just emptyBill
                                      }
                                    , Cmd.none
                                    )

                                Just bill ->
                                    -- Edit bill
                                    ( { model
                                        | modal = modal_type
                                        , selectedBill = Just bill
                                      }
                                    , Cmd.none
                                    )

                        Hidden ->
                            let
                                fields =
                                    model.fields
                                        |> setNewMemberName ""
                                        |> setNewMemberWeight ""
                            in
                            ( { model
                                | modal = modal_type
                                , fields = fields
                                , selectedBill = Nothing
                              }
                            , Cmd.none
                            )

                Nothing ->
                    ( model, Cmd.none )

        DeactivateMember member_id ->
            case model.project of
                Just project ->
                    ( model
                    , deleteProjectMember model.auth member_id
                    )

                Nothing ->
                    ( model, Cmd.none )

        SelectBill bill ->
            case model.modal of
                Hidden ->
                    ( { model | selectedBill = bill }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        RemoveBill bill ->
            case model.project of
                Just project ->
                    ( model
                    , deleteProjectBill model.auth bill.id
                    )

                Nothing ->
                    ( model, Cmd.none )

        BillUpdate bill (Ok id) ->
            case model.project of
                Just project ->
                    let
                        newBill =
                            { bill | id = id }

                        newProject =
                            { project
                                | bills =
                                    List.filter (\b -> b.id /= bill.id) project.bills
                                        |> List.append [ newBill ]
                                        |> List.sortBy .date
                                        |> List.reverse
                            }
                    in
                    ( { model
                        | project = Just newProject
                        , selectedBill = Nothing
                        , modal = Hidden
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        BillUpdate bill (Err err) ->
            let
                _ =
                    Debug.log "Error while adding the bill" err
            in
            ( model, Cmd.none )

        BillDeleted bill_id (Ok _) ->
            case model.project of
                Just project ->
                    let
                        newProject =
                            setDeletedProjectBill bill_id project
                    in
                    ( { model
                        | project = Just newProject
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        BillDeleted bill_id (Err err) ->
            let
                _ =
                    Debug.log ("Error while removing the bill " ++ String.fromInt bill_id) err
            in
            ( model, Cmd.none )

        NewBillDate bill date ->
            ( { model | selectedBill = Just { bill | date = date } }, Cmd.none )

        NewBillLabel bill label ->
            ( { model | selectedBill = Just { bill | label = label } }, Cmd.none )

        NewBillPayer bill payer ->
            ( { model | selectedBill = Just { bill | payer = payer } }, Cmd.none )

        NewBillAmount bill amount ->
            ( { model
                | selectedBill =
                    Just
                        { bill
                            | amount =
                                Maybe.withDefault 0.0 <|
                                    String.toFloat amount
                        }
              }
            , Cmd.none
            )

        NewBillToggleOwer bill ower ->
            let
                isOwer =
                    (List.filter (\o -> o.id == ower.id) bill.owers |> List.length) == 1
            in
            if isOwer then
                ( { model | selectedBill = Just { bill | owers = List.filter (\o -> o.id /= ower.id) bill.owers } }
                , Cmd.none
                )

            else
                ( { model | selectedBill = Just { bill | owers = List.append bill.owers [ ower ] } }
                , Cmd.none
                )

        NewBillToggleAllOwers bill members ->
            ( { model | selectedBill = Just { bill | owers = members } }, Cmd.none )

        NewBillToggleNoneOwers bill ->
            ( { model | selectedBill = Just { bill | owers = [] } }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Document Msg
view model =
    let
        t =
            getString model.locale
    in
    case ( model.auth, model.project ) of
        ( Basic user password, Just project ) ->
            { title = t <| AppTitle (Just project.name)
            , body =
                [ navBarView t project model.locale
                , handleModal t model project
                , div
                    [ class "container-fluid" ]
                    [ sideBarView t model.fields.newMember project.members project.bills model.selectedBill
                    , billBoardView t project.members project.bills
                    ]
                , div [ class "messages" ] []
                , footerView t
                ]
            }

        ( _, _ ) ->
            { title = t <| AppTitle Nothing
            , body =
                [ simpleNavBarView t model.locale
                , loginView t model.locale model.fields
                , footerView t
                ]
            }
