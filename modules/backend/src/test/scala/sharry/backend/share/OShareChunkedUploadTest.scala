package sharry.backend.share

import cats.effect.*
import fs2.Stream

import sharry.common.*
import sharry.store.*
import sharry.store.records.{RAccount, RShare}

import binny.ByteRange
import munit.FunSuite

/** Regression test for a bug where uploading a file in more than one TUS chunk
  * corrupted `filemeta.length`, causing the next chunk to fail with
  * `InvalidChunkIndex` and leaving the file truncated at the first chunk's size.
  */
class OShareChunkedUploadTest extends FunSuite with StoreFixture {

  private val chunkSize = 64L * 1024 // matches StoreFixture's FileStore chunk size
  private val cfg = ShareConfig(
    chunkSize = ByteSize(chunkSize),
    maxSize = ByteSize(100L * 1024 * 1024),
    maxValidity = Duration.days(1),
    databaseDomainChecks = Nil,
    zipMaxSize = ByteSize(100L * 1024 * 1024),
    requireSharePassword = false
  )

  // first chunk is exactly two store-chunks; a second, smaller chunk is
  // needed to complete the file - this is what triggered the bug
  private val chunk1Size = (chunkSize * 2).toInt
  private val chunk2Size = chunkSize.toInt
  private val totalSize = ByteSize((chunk1Size + chunk2Size).toLong)

  private def bytes(n: Int, fill: Byte): Stream[IO, Byte] =
    Stream.emits(Array.fill(n)(fill)).covary[IO]

  test("uploading a file across multiple PATCH chunks stores the full content") {
    withStore { store =>
      OShare[IO](store, cfg).use { oshare =>
        for {
          now <- Timestamp.current[IO]
          accountId <- Ident.randomId[IO]
          account = RAccount(
            accountId,
            CIIdent.unsafe("jdoe"),
            AccountSource.intern,
            AccountState.Active,
            Password("test"),
            None,
            admin = true,
            0,
            None,
            now
          )
          _ <- store.transact(RAccount.insert(account, "warn"))
          accId = account.accountId(None)

          shareId <- Ident.randomId[IO]
          share = RShare(shareId, accountId, None, None, Duration.days(1), 0, None, None, now)
          _ <- store.transact(RShare.insert(share))

          createRes <- oshare
            .createEmptyFile(
              shareId,
              accId,
              FileInfo(totalSize, Some("test.bin"), "application/octet-stream")
            )
            .value
          fileId = createRes match {
            case Some(UploadResult.Success(id)) => id
            case other                          => fail(s"Could not create empty file: $other")
          }

          firstRes <- oshare
            .addFileData(
              shareId,
              fileId,
              accId,
              Some(ByteSize(chunk1Size.toLong)),
              ByteSize.zero,
              bytes(chunk1Size, 1)
            )
            .value
          _ <- IO(
            assertEquals(firstRes, Some(UploadResult.success(ByteSize(chunk1Size.toLong))))
          )

          secondRes <- oshare
            .addFileData(
              shareId,
              fileId,
              accId,
              Some(ByteSize(chunk2Size.toLong)),
              ByteSize(chunk1Size.toLong),
              bytes(chunk2Size, 2)
            )
            .value
          _ <- IO(assertEquals(secondRes, Some(UploadResult.success(totalSize))))

          descOpt <- store.transact(Queries.fileDesc(fileId))
          desc = descOpt.getOrElse(fail("file description not found"))

          meta <- store.fileStore.findMeta(desc.metaId).value
          _ <- IO(assertEquals(meta.map(_.length), Some(totalSize)))

          binaryOpt <- store.fileStore.findBinary(desc.metaId, ByteRange.All).value
          binary = binaryOpt.getOrElse(fail("binary not found"))
          content <- binary.compile.toVector

          expected = Vector.fill(chunk1Size)(1.toByte) ++ Vector.fill(chunk2Size)(2.toByte)
          _ <- IO(assertEquals(content, expected))
        } yield ()
      }
    }
  }
}
