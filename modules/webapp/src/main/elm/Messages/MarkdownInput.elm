module Messages.MarkdownInput exposing
    ( Texts
    , de
    , gb
    )


type alias Texts =
    { edit : String
    , preview : String
    , split : String
    , supportsMarkdown : String
    }


gb : Texts
gb =
    { edit = "Edit"
    , preview = "Preview"
    , split = "Split"
    , supportsMarkdown = "Supports Markdown"
    }


de : Texts
de =
    { edit = "Editieren"
    , preview = "Vorschau"
    , split = "Geteilt"
    , supportsMarkdown = "Unterstützt Markdown"
    }
