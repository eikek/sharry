module Messages.MarkdownInput exposing
    ( MarkdownInput
    , gb
    )


type alias MarkdownInput =
    { edit : String
    , preview : String
    , split : String
    , supportsMarkdown : String
    }


gb : MarkdownInput
gb =
    { edit = "Edit"
    , preview = "Preview"
    , split = "Split"
    , supportsMarkdown = "Supports Markdown"
    }
