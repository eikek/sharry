module Messages.MarkdownInput exposing
    ( Texts
    , de
    , gb
    , fr
    , ja
    , cz
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

fr : Texts
fr =
    { edit = "Éditer"
    , preview = "Prévisualiser"
    , split = "Vue séparée"
    , supportsMarkdown = "Supporte le Markdown"
    }

ja : Texts
ja =
    { edit = "編集"
    , preview = "プレビュー"
    , split = "分割"
    , supportsMarkdown = "マークダウン サポート"
    }

cz : Texts
cz =
    { edit = "Editovat"
    , preview = "Náhled"
    , split = "Rozdělit"
    , supportsMarkdown = "Podporuje Markdown"
    }
