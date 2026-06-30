-- Fix filemeta.length for existing files.
-- H2 in PostgreSQL mode: LENGTH() on both MEDIUMBLOB and VARBINARY returns UTF-8
-- character count, not byte count. OCTET_LENGTH() is reliable on MEDIUMBLOB, so
-- no column type change is needed. New uploads are fixed in OShare.scala via
-- Scala-computed updateLength() which never calls LENGTH() on chunk_data.
--
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
