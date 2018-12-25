module Types exposing
    ( Authentication(..)
    , Bill
    , Fields
    , Locale(..)
    , LocaleIdentifier(..)
    , Localizer
    , Member
    , Model
    , Msg(..)
    , Project
    )


type alias Model =
    { auth : Authentication
    , locale : Locale
    , project : String
    , members : List Member
    , bills : List Bill
    , fields : Fields
    }


type alias Fields =
    { newMember : String
    , loginProjectID : String
    , loginPassword : String
    , newProjectName : String
    , newProjectPassword : String
    , newProjectEmail : String
    }


type Authentication
    = Basic String String
    | Unauthenticated


type Msg
    = NewMemberName String
    | AddMember
    | LoginProjectID String
    | LoginPassword String
    | Login
    | LogoutUser
    | NewProjectName String
    | NewProjectPassword String
    | NewProjectEmail String
    | CreateProject
    | ChangeLocale Locale


type alias Project =
    String


type alias Member =
    { name : String
    , balance : Float
    }


type alias Bill =
    { date : String
    , amount : Float
    , label : String
    , payer : String
    , owers : List String
    }


type Locale
    = EN
    | FR


type alias Localizer =
    LocaleIdentifier -> String


type LocaleIdentifier
    = AppTitle (Maybe String)
    | Bills
    | Settle
    | Statistics
    | Options
    | ProjectSettings
    | StartNewProject
    | Logout
    | TypeUserName
    | Add
    | Deactivate
    | Edit
    | Delete
    | Invite
    | FreeSoftware
    | YouCanContribute
    | AddNewBill
    | When
    | WhoPaid
    | ForWhat
    | ForWhom
    | HowMuch
    | Actions
    | Each String
    | ManageYourExpenses
    | EasilyShared
    | TryDemo
    | SharingHouse
    | GoingOnHoliday
    | SimplySharingMoney
    | WeCanHelp
    | LogToExistingProject
    | ProjectID
    | PrivateCode
    | LogIn
    | CantRememberPassword
    | CreateNewProject
    | ProjectName
    | Email
    | LetsGetStarted
