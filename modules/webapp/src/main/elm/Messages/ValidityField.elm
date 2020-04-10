module Messages.ValidityField exposing
    ( Texts
    , gb
    )

import Messages.FixedDropdown


type alias Texts =
    { dropdown : Messages.FixedDropdown.Texts
    }


gb : Texts
gb =
    { dropdown = Messages.FixedDropdown.gb
    }
