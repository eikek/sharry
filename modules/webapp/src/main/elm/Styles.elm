module Styles exposing (..)


styleQr : String
styleQr =
    "dark:bg-warmgray-400 bg-gray-50 mx-auto md:mx-0"


content : String
content =
    "container mx-auto px-2 overflow-y-auto scrollbar-main scrollbar-thin"


successMessage : String
successMessage =
    " border border-green-600 bg-green-50 text-green-600 dark:border-lime-800 dark:bg-lime-300 dark:text-lime-800 px-4 py-2 rounded "


successMessageLink : String
successMessageLink =
    "text-green-700 hover:text-green-800 dark:text-lime-800 dark:hover:text-lime-700 underline "


errorMessage : String
errorMessage =
    " border border-red-600 bg-red-50 text-red-600 dark:border-orange-800 dark:bg-orange-300 dark:text-orange-800 px-2 py-2 rounded "


warnMessage : String
warnMessage =
    warnMessageColors ++ " border dark:bg-opacity-25 px-2 py-2 rounded "


warnMessageColors : String
warnMessageColors =
    " border-yellow-800 bg-yellow-50 text-yellow-800 dark:border-amber-200 dark:bg-amber-800 dark:text-amber-200 "


infoMessage : String
infoMessage =
    " border border-blue-800 bg-blue-100 text-blue-800 dark:border-lightblue-200 dark:bg-lightblue-800 dark:text-lightblue-200 dark:bg-opacity-25 px-2 py-2 rounded "


message : String
message =
    " border border-gray-600 bg-gray-50 text-gray-600 "
        ++ "dark:border-warmgray-500 dark:bg-warmgray-700 dark:bg-opacity-80 dark:text-warmgray-400 "
        ++ "px-4 py-2 rounded "


greenSolidLabel : String
greenSolidLabel =
    " label border-green-500 bg-green-500 text-white dark:border-lime-800 dark:bg-lime-300 dark:text-lime-800 "


greenBasicLabel : String
greenBasicLabel =
    " label border-green-500 text-green-500 dark:border-lime-300 dark:text-lime-300 "


redSolidLabel : String
redSolidLabel =
    " label border-red-500 bg-red-500 text-white dark:border-orange-800 dark:bg-orange-200 dark:text-orange-800 "


redBasicLabel : String
redBasicLabel =
    " label border-red-500 text-red-500 dark:border-orange-200 dark:text-orange-200 "


basicLabel : String
basicLabel =
    " label border-gray-600 text-gray-600 dark:border-warmgray-300 dark:text-warmgray-300 "



--- Primary Button


primaryButton : String
primaryButton =
    primaryButtonRounded ++ primaryButtonPlain


primaryButtonPlain : String
primaryButtonPlain =
    primaryButtonMain ++ primaryButtonHover


primaryButtonMain : String
primaryButtonMain =
    " my-auto whitespace-nowrap bg-blue-500 border border-blue-500 dark:border-lightblue-800 dark:bg-lightblue-800 text-white text-center px-4 py-2 shadow-md focus:outline-none focus:ring focus:ring-opacity-75 "


primaryButtonHover : String
primaryButtonHover =
    " hover:bg-blue-600 dark:hover:bg-lightblue-700 "


primaryButtonRounded : String
primaryButtonRounded =
    " rounded "



--- Primary Basic Button


primaryBasicButton : String
primaryBasicButton =
    primaryBasicButtonMain ++ primaryBasicButtonHover


primaryBasicButtonMain : String
primaryBasicButtonMain =
    " rounded my-auto whitespace-nowrap border border-blue-500 dark:border-lightblue-500 text-blue-500 dark:text-lightblue-500 text-center px-4 py-2 shadow-md focus:outline-none focus:ring focus:ring-opacity-75 "


primaryBasicButtonHover : String
primaryBasicButtonHover =
    " hover:bg-blue-600 hover:text-white dark:hover:text-white dark:hover:bg-lightblue-500 "



--- Secondary Button


secondaryButton : String
secondaryButton =
    secondaryButtonMain ++ secondaryButtonHover


secondaryButtonMain : String
secondaryButtonMain =
    " rounded " ++ secondaryButtonPlain


secondaryButtonPlain : String
secondaryButtonPlain =
    " my-auto whitespace-nowrap bg-gray-300 text-gray-800 dark:bg-warmgray-400 text-center px-4 py-2 shadow-md focus:outline-none focus:ring focus:ring-opacity-75 dark:text-gray-800 "


secondaryButtonHover : String
secondaryButtonHover =
    " hover:bg-gray-400 dark:hover:bg-warmgray-300 "



--- Secondary Basic Button


secondaryBasicButton : String
secondaryBasicButton =
    secondaryBasicButtonRounded ++ secondaryBasicButtonPlain


secondaryBasicButtonPlain : String
secondaryBasicButtonPlain =
    secondaryBasicButtonMain ++ secondaryBasicButtonHover


secondaryBasicButtonToggle : Bool -> String
secondaryBasicButtonToggle active =
    let
        base =
            secondaryBasicButtonRounded
                ++ String.replace "text-gray-500 dark:text-warmgray-400" "" secondaryBasicButtonMain
    in
    if active then
        base ++ secondaryBasicButtonActive

    else
        base ++ "text-gray-500 dark:text-warmgray-400" ++ secondaryBasicButtonHover


secondaryBasicButtonRounded : String
secondaryBasicButtonRounded =
    " rounded border px-4 py-2 "


secondaryBasicButtonMain : String
secondaryBasicButtonMain =
    " my-auto whitespace-nowrap border-gray-500 dark:border-warmgray-500 text-gray-500 dark:text-warmgray-400 text-center shadow-none focus:outline-none focus:ring focus:ring-opacity-75 "


secondaryBasicButtonHover : String
secondaryBasicButtonHover =
    " hover:bg-gray-600 hover:text-white dark:hover:text-white dark:hover:bg-warmgray-500 dark:hover:text-warmgray-100 "


secondaryBasicButtonActive : String
secondaryBasicButtonActive =
    " bg-gray-600 text-white dark:text-white dark:bg-warmgray-500 dark:text-warmgray-100 "



--- Delete Button


deleteButton : String
deleteButton =
    " rounded my-auto whitespace-nowrap border border-red-500 dark:border-lightred-500 text-red-500 dark:text-orange-500 text-center px-4 py-2 shadow-none focus:outline-none focus:ring focus:ring-opacity-75 hover:bg-red-600 hover:text-white dark:hover:text-white dark:hover:bg-orange-500 dark:hover:text-warmgray-900 "


deleteLabel : String
deleteLabel =
    "label my-auto whitespace-nowrap border border-red-500 dark:border-lightred-500 text-red-500 dark:text-orange-500 text-center focus:outline-none focus:ring focus:ring-opacity-75 hover:bg-red-600 hover:text-white dark:hover:text-white dark:hover:bg-orange-500 dark:hover:text-warmgray-900"



--- Others


link : String
link =
    " text-blue-400 hover:text-blue-500 dark:text-lightblue-300 dark:hover:text-lightblue-200 cursor-pointer "


inputErrorBorder : String
inputErrorBorder =
    " border-red-600 dark:border-orange-600 "


inputLabel : String
inputLabel =
    " text-sm font-semibold py-0.5 "


textInput : String
textInput =
    " placeholder-gray-400 w-full dark:text-warmgray-200 dark:bg-warmgray-800 dark:border-warmgray-500 border-gray-400 rounded " ++ formFocusRing


textInputSidebar : String
textInputSidebar =
    " w-full placeholder-gray-400 border-gray-400 bg-blue-50 dark:text-warmgray-200 dark:bg-warmgray-700 dark:border-warmgray-500 rounded " ++ formFocusRing


textAreaInput : String
textAreaInput =
    "block" ++ textInput


inputIcon : String
inputIcon =
    "absolute left-3 top-3 w-10 text-gray-400 dark:text-warmgray-400  "


dateInputIcon : String
dateInputIcon =
    "absolute left-3 top-3 w-10 text-gray-400 dark:text-warmgray-400  "


inputLeftIconLink : String
inputLeftIconLink =
    "inline-flex items-center justify-center absolute right-0 top-0 h-full w-10 rounded-r cursor-pointer "
        ++ "text-gray-400 dark:text-warmgray-400 "
        ++ "bg-gray-300 dark:bg-warmgray-700 "
        ++ "dark:border-warmgray-500 border-0 border-r border-t border-b border-gray-500 "
        ++ "hover:bg-gray-400 hover:text-gray-700 dark:hover:bg-warmgray-600"


inputLeftIconLinkSidebar : String
inputLeftIconLinkSidebar =
    "inline-flex items-center justify-center absolute right-0 top-0 h-full w-10 rounded-r cursor-pointer "
        ++ "text-gray-400 dark:text-warmgray-400 "
        ++ "bg-gray-300 dark:bg-warmgray-600 "
        ++ "dark:border-warmgray-500 border-0 border-r border-t border-b border-gray-500 "
        ++ "hover:bg-gray-400 hover:text-gray-700 dark:hover:bg-warmgray-500"


inputLeftIconOnly : String
inputLeftIconOnly =
    "inline-flex items-center justify-center absolute right-0 top-0 h-full w-10 rounded-r "
        ++ "dark:border-warmgray-500 border-0 border-r border-t border-b border-gray-500 "


checkboxInput : String
checkboxInput =
    " checkbox w-5 h-5 md:w-4 md:h-4 text-black  dark:text-warmgray-600 dark:bg-warmgray-600 dark:border-warmgray-700" ++ formFocusRing


formFocusRing : String
formFocusRing =
    " focus:ring focus:ring-black focus:ring-opacity-50 focus:ring-offset-0 dark:focus:ring-warmgray-400 "


radioInput : String
radioInput =
    checkboxInput


box : String
box =
    " border dark:border-warmgray-500 bg-white dark:bg-warmgray-800 shadow-md "


border : String
border =
    " border dark:border-warmgray-600 "


header1 : String
header1 =
    " text-3xl mt-3 mb-5 font-semibold tracking-wide "


header2 : String
header2 =
    " text-2xl mb-3 font-medium tracking-wide "


header3 : String
header3 =
    " text-xl mb-3 font-medium tracking-wide "


editLinkTableCellStyle : String
editLinkTableCellStyle =
    "w-px whitespace-nowrap pr-2 md:pr-4 py-4 md:py-2"


dimmer : String
dimmer =
    " absolute top-0 left-0 w-full h-full bg-black bg-opacity-90 dark:bg-warmgray-900 dark:bg-opacity-90 z-50 flex flex-col items-center justify-center px-4 md:px-8 py-2 "


dimmerLight : String
dimmerLight =
    " absolute top-0 left-0 w-full h-full bg-black bg-opacity-60 dark:bg-warmgray-900 dark:bg-opacity-60 z-30 flex flex-col items-center justify-center px-4 py-2 "


dimmerCard : String
dimmerCard =
    " absolute top-0 left-0 w-full h-full bg-black bg-opacity-60 dark:bg-lightblue-900 dark:bg-opacity-60 z-30 flex flex-col items-center justify-center px-4 py-2 "


tableMain : String
tableMain =
    "border-collapse table w-full dark:text-warmgray-300"


tableRow : String
tableRow =
    "border-t dark:border-warmgray-600"


published : String
published =
    "text-green-500 fa fa-circle"


unpublished : String
unpublished =
    "fa fa-circle font-thin"


publishError : String
publishError =
    "text-red-500 fa fa-bolt"
