module Data.DropdownStyle exposing
    ( DropdownStyle
    , mainStyle
    , mainStyleWith
    , sidebarStyle
    )

import Styles as S


type alias DropdownStyle =
    { root : String
    , link : String
    , menu : String
    , item : String
    , itemActive : String
    , input : String
    }


mainStyle : DropdownStyle
mainStyle =
    { root = ""
    , link = dropdownLinkStyle ++ mainLink
    , menu = dropdownMenuStyle ++ mainMenu
    , item = dropdownItemStyle ++ mainItem
    , itemActive = "bg-gray-200 dark:bg-stone-700"
    , input = mainInputStyle
    }


mainStyleWith : String -> DropdownStyle
mainStyleWith rootClass =
    let
        ds =
            mainStyle
    in
    { ds | root = rootClass }


sidebarStyle : DropdownStyle
sidebarStyle =
    { root = ""
    , link = dropdownLinkStyle ++ sidebarLink
    , menu = dropdownMenuStyle ++ sidebarMenu
    , item = dropdownItemStyle ++ sidebarItem
    , itemActive = "bg-gray-300 dark:bg-stone-600"
    , input = sidebarInputStyle
    }


dropdownLinkStyle : String
dropdownLinkStyle =
    "py-2 px-4 w-full inline-flex items-center border rounded "
        ++ S.formFocusRing


mainLink : String
mainLink =
    " bg-white border-gray-500 hover:border-gray-500 dark:bg-stone-800 dark:border-stone-500 dark:hover:border-stone-500"


sidebarLink : String
sidebarLink =
    " bg-blue-50 border-gray-500 hover:border-gray-500 dark:bg-stone-700 dark:border-stone-400 dark:hover:border-stone-400"


dropdownMenuStyle : String
dropdownMenuStyle =
    "absolute left-0 max-h-44 w-full overflow-y-auto z-50 border shadow-lg transition duration-200 "


mainMenu : String
mainMenu =
    "bg-white dark:bg-stone-800 dark:border-stone-700 dark:text-stone-300"


sidebarMenu : String
sidebarMenu =
    "bg-blue-50 dark:bg-stone-700 dark:border-stone-600 dark:text-stone-200"


dropdownItemStyle : String
dropdownItemStyle =
    "transition-colors duration-200 items-center block px-4 py-2 text-normal "


mainItem : String
mainItem =
    " hover:bg-gray-200 dark:hover:bg-stone-700 dark:hover:text-stone-100"


sidebarItem : String
sidebarItem =
    " hover:bg-gray-300 dark:hover:bg-stone-600 dark:hover:text-stone-50"


mainInputStyle : String
mainInputStyle =
    "dark:text-stone-200 dark:bg-stone-800 dark:border-stone-500"


sidebarInputStyle : String
sidebarInputStyle =
    "bg-blue-50 dark:text-stone-200 dark:bg-stone-700 dark:border-stone-400"
