-- change all columns that carry a timestamp from varchar to timestamp

-- account_  (lastlogin, created)
ALTER TABLE "account_" RENAME COLUMN "created" TO "created_old";
ALTER TABLE "account_" ADD COLUMN "created" timestamp;
UPDATE "account_" SET "created" = CAST("created_old" as timestamp);
ALTER TABLE "account_" ALTER COLUMN "created" SET NOT NULL;
ALTER TABLE "account_" DROP COLUMN "created_old";

ALTER TABLE "account_" RENAME COLUMN "lastlogin" TO "lastlogin_old";
ALTER TABLE "account_" ADD COLUMN "lastlogin" timestamp;
UPDATE "account_" SET "lastlogin" = CAST("lastlogin_old" as timestamp);
ALTER TABLE "account_" DROP COLUMN "lastlogin_old";

-- alias_ (created)
ALTER TABLE "alias_" RENAME COLUMN "created" TO "created_old";
ALTER TABLE "alias_" ADD COLUMN "created" timestamp;
UPDATE "alias_" SET "created" = CAST("created_old" as timestamp);
ALTER TABLE "alias_" ALTER COLUMN "created" SET NOT NULL;
ALTER TABLE "alias_" DROP COLUMN "created_old";

-- invitation (created)
ALTER TABLE "invitation" RENAME COLUMN "created" TO "created_old";
ALTER TABLE "invitation" ADD COLUMN "created" timestamp;
UPDATE "invitation" SET "created" = CAST("created_old" as timestamp);
ALTER TABLE "invitation" ALTER COLUMN "created" SET NOT NULL;
ALTER TABLE "invitation" DROP COLUMN "created_old";

-- publish_share (created, publish_date, publish_until, last_access)
ALTER TABLE "publish_share" RENAME COLUMN "created" TO "created_old";
ALTER TABLE "publish_share" ADD COLUMN "created" timestamp;
UPDATE "publish_share" SET "created" = CAST("created_old" as timestamp);
ALTER TABLE "publish_share" ALTER COLUMN "created" SET NOT NULL;
ALTER TABLE "publish_share" DROP COLUMN "created_old";

ALTER TABLE "publish_share" RENAME COLUMN "publish_date" TO "publish_date_old";
ALTER TABLE "publish_share" ADD COLUMN "publish_date" timestamp;
UPDATE "publish_share" SET "publish_date" = CAST("publish_date_old" as timestamp);
ALTER TABLE "publish_share" ALTER COLUMN "publish_date" SET NOT NULL;
ALTER TABLE "publish_share" DROP COLUMN "publish_date_old";

ALTER TABLE "publish_share" RENAME COLUMN "publish_until" TO "publish_until_old";
ALTER TABLE "publish_share" ADD COLUMN "publish_until" timestamp;
UPDATE "publish_share" SET "publish_until" = CAST("publish_until_old" as timestamp);
ALTER TABLE "publish_share" ALTER COLUMN "publish_until" SET NOT NULL;
ALTER TABLE "publish_share" DROP COLUMN "publish_until_old";

ALTER TABLE "publish_share" RENAME COLUMN "last_access" TO "last_access_old";
ALTER TABLE "publish_share" ADD COLUMN "last_access" timestamp;
UPDATE "publish_share" SET "last_access" = CAST("last_access_old" as timestamp);
ALTER TABLE "publish_share" DROP COLUMN "last_access_old";

-- share (created)
ALTER TABLE "share" RENAME COLUMN "created" TO "created_old";
ALTER TABLE "share" ADD COLUMN "created" timestamp;
UPDATE "share" SET "created" = CAST("created_old" as timestamp);
ALTER TABLE "share" ALTER COLUMN "created" SET NOT NULL;
ALTER TABLE "share" DROP COLUMN "created_old";

-- share_file (created)
ALTER TABLE "share_file" RENAME COLUMN "created" TO "created_old";
ALTER TABLE "share_file" ADD COLUMN "created" timestamp;
UPDATE "share_file" SET "created" = CAST("created_old" as timestamp);
ALTER TABLE "share_file" ALTER COLUMN "created" SET NOT NULL;
ALTER TABLE "share_file" DROP COLUMN "created_old";
