package sharry.store.binary

import java.time.Instant
import fs2.{Pipe, Stream, Task}
import sharry.common.sizes._
import sharry.store.range._
import sharry.store.data._
import sharry.store.mimedetect._

/** A store for binary data.
  *
  * This module only knows about `contentType', but any other
  * information about the content is opaque to this store. The content
  * id of the content is SHA checksum and thus it can check for
  * duplicates. By default (the `save` method) will insert the new
  * data, check if it already exists to either delete the new data and
  * return the old or insert the new data.
  *
  * The result is wrapped in `Outcome` type which signals, whether the
  * data has been inserted or already existed.
  */
trait BinaryStore {
  /** Save data in chunks of size `chunkSize` and use a random id.
    *
    * Save the data and do no duplicate checks. Return a tuple where
    * the first component is the new (random) id and the second the
    * meta data containing the “real” key. Make the data “final” by
    * invoking `makeFinal` which will check for duplicates and either
    * updates the random key with the one in `meta` or returns an
    * existing meta object.
    */
  def saveTemp(data: Stream[Task, Byte], chunkSize: Size, mimeInfo: MimeInfo, time: Instant): Stream[Task, (String, FileMeta)]

  /** Giving a “temporary key”, check for duplicates. If a duplicate is
    * found, delete the temporary data and return the existing `meta`
    * object. Otherwise update the temporary id and save the `meta`
    * object.*/
  def makeFinal(k: (String, FileMeta)): Stream[Task, Outcome[FileMeta]]

  /** Save the data and make it final afterwards. */
  def save(data: Stream[Task, Byte], chunkSize: Size, mimeInfo: MimeInfo, time: Instant): Stream[Task, Outcome[FileMeta]] =
    for {
      t    <- saveTemp(data, chunkSize, mimeInfo, time)
      meta <- makeFinal(t)
    } yield meta

  def get(id: String): Stream[Task, Option[FileMeta]]

  /** Fetch data using one connection per chunk. So connections are
    * closed immediately after reading a chunk. */
  def fetchData(range: RangeSpec): Pipe[Task, FileMeta, Byte]

  /** Fetch data using one connection for the whole stream. It is closed
    * once the stream terminates. */
  def fetchData2(range: RangeSpec): Pipe[Task, FileMeta, Byte]

  def exists(id: String): Stream[Task, Boolean]
  def delete(id: String): Stream[Task, Boolean]
  def count: Stream[Task, Int]

  // low level
  def saveFileMeta(fm: FileMeta): Stream[Task, Unit]
  def saveFileChunk(fc: FileChunk): Stream[Task, Unit]
}
