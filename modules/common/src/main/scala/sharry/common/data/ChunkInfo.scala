package sharry.common.data

/** Info provided by every chunk that is uploaded. The {{{token}}} is
  * the upload id. */
case class ChunkInfo(
  token: String
    , chunkNumber: Int
    , chunkSize: Int
    , currentChunkSize: Int
    , totalSize: Long
    , fileIdentifier: String
    , filename: String
    , totalChunks: Int
)
