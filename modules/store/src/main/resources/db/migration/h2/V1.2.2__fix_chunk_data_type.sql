-- Fix: change chunk_data from BLOB/MEDIUMBLOB back to VARBINARY.
-- H2's LENGTH() on BLOB columns (introduced by V1.0.1) returns UTF-8 character
-- count instead of byte count, causing filemeta.length to be underreported.
-- NOTE: Even with VARBINARY, LENGTH() still returns char count in H2 PostgreSQL
-- mode; the Scala-level updateLength() in OShare.scala bypasses this for new uploads.
ALTER TABLE "filechunk" ALTER COLUMN "chunk_data" VARBINARY(1000000000) NOT NULL;

-- Recompute filemeta.length for existing files using correct byte count.
-- Only updates rows that have chunks (files uploaded before this migration).
UPDATE "filemeta"
SET "length" = (
  SELECT SUM(OCTET_LENGTH(fc."chunk_data"))
  FROM "filechunk" fc
  WHERE fc."file_id" = "filemeta"."file_id"
)
WHERE EXISTS (
  SELECT 1 FROM "filechunk" fc2 WHERE fc2."file_id" = "filemeta"."file_id"
);
