package sharry.store

import java.sql.{Connection, DriverManager}

import munit.FunSuite

/** Regression test for issues #1327 / #899.
  *
  * Verifies that the V1.2.2 migration UPDATE correctly recomputes
  * filemeta.length using OCTET_LENGTH on MEDIUMBLOB chunk_data in H2
  * PostgreSQL mode (where LENGTH() returns UTF-8 char count, not bytes).
  *
  * Also confirms that OCTET_LENGTH on MEDIUMBLOB returns byte count,
  * which is the precondition for removing the ALTER TABLE from V1.2.2.
  */
class H2BlobLengthTest extends FunSuite {

  // Post-V1.2.1 schema for the two tables touched by V1.2.2.
  private val createFilemeta =
    """CREATE TABLE "filemeta" (
      |  "file_id"   varchar(254) not null primary key,
      |  "mimetype"  varchar(254) not null,
      |  "length"    bigint not null,
      |  "checksum"  varchar(254) not null,
      |  "created"   timestamp not null
      |)""".stripMargin

  private val createFilechunk =
    """CREATE TABLE "filechunk" (
      |  "file_id"   varchar(254) not null,
      |  "chunk_nr"  int not null,
      |  "chunk_len" int not null,
      |  "chunk_data" MEDIUMBLOB not null,
      |  primary key ("file_id", "chunk_nr")
      |)""".stripMargin

  // The V1.2.2 UPDATE statement (copied verbatim).
  private val v122Update =
    """UPDATE "filemeta"
      |SET "length" = (
      |  SELECT SUM(OCTET_LENGTH(fc."chunk_data"))
      |  FROM "filechunk" fc
      |  WHERE fc."file_id" = "filemeta"."file_id"
      |)
      |WHERE EXISTS (
      |  SELECT 1 FROM "filechunk" fc2 WHERE fc2."file_id" = "filemeta"."file_id"
      |)""".stripMargin

  private def withConn[A](dbName: String)(f: Connection => A): A = {
    val url =
      s"jdbc:h2:mem:$dbName;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1"
    val conn = DriverManager.getConnection(url, "sa", "")
    try f(conn)
    finally conn.close()
  }

  test("OCTET_LENGTH on MEDIUMBLOB returns byte count") {
    withConn("octet_length_check") { conn =>
      val st = conn.createStatement()
      st.execute("CREATE TABLE t (data MEDIUMBLOB NOT NULL)")
      // X'C3A9' = UTF-8 for 'é': 2 bytes, 1 code point
      st.execute("INSERT INTO t VALUES (X'C3A9')")
      val rs = st.executeQuery("SELECT OCTET_LENGTH(data) FROM t")
      rs.next()
      assertEquals(rs.getLong(1), 2L)
    }
  }

  test("V1.2.2 UPDATE recomputes filemeta.length from chunk bytes") {
    withConn("migration_v122") { conn =>
      val st = conn.createStatement()
      st.execute(createFilemeta)
      st.execute(createFilechunk)

      // Seed: file with two chunks — 2 bytes + 3 bytes = 5 bytes total.
      // filemeta.length is intentionally wrong (1) to simulate the bug.
      st.execute(
        """INSERT INTO "filemeta" VALUES
          |  ('file-1', 'application/octet-stream', 1, 'checksum-1', CURRENT_TIMESTAMP)
          |""".stripMargin
      )
      // X'C3A9' = 2 bytes; X'FFFFFF' = 3 bytes
      st.execute(
        """INSERT INTO "filechunk" VALUES
          |  ('file-1', 0, 2, X'C3A9'),
          |  ('file-1', 1, 3, X'FFFFFF')
          |""".stripMargin
      )

      // Seed: file with no chunks — length must not be touched.
      st.execute(
        """INSERT INTO "filemeta" VALUES
          |  ('file-2', 'text/plain', 99, 'checksum-2', CURRENT_TIMESTAMP)
          |""".stripMargin
      )

      st.execute(v122Update)

      val rs = st.executeQuery(
        """SELECT "file_id", "length" FROM "filemeta" ORDER BY "file_id""""
      )

      rs.next()
      assertEquals(rs.getString(1), "file-1")
      assertEquals(rs.getLong(2), 5L, "file-1 length must equal sum of chunk bytes")

      rs.next()
      assertEquals(rs.getString(1), "file-2")
      assertEquals(rs.getLong(2), 99L, "file-2 (no chunks) must not be modified")
    }
  }
}
