CREATE TABLE IF NOT EXISTS "filemeta" (
  "id" varchar(254) not null primary key,
  "timestamp" varchar(40) not null,
  "mimetype" varchar(254) not null,
  "length" bigint not null,
  "checksum" varchar(254) not null,
  "chunks" int not null,
  "chunksize" int not null
);

CREATE TABLE IF NOT EXISTS "filechunk" (
  fileId varchar(254) not null,
  chunkNr int not null,
  chunkLength int not null,
  chunkData bytea not null,
  primary key (fileId, chunkNr)
);

CREATE TABLE "account_" (
  "id" varchar(254) not null primary key,
  "login" varchar(254) not null,
  "source" varchar(254) not null,
  "state" varchar(254) not null,
  "password" varchar(254) not null,
  "email" varchar(254),
  "admin" boolean not null,
  "logincount" int not null,
  "lastlogin" varchar(40),
  "created" varchar(40) not null,
  unique("login")
);

CREATE TABLE "invitation" (
  "id" varchar(254) not null primary key,
  "created" varchar(40) not null
);

CREATE TABLE "alias_" (
  "id" varchar(254) not null primary key,
  "account_id" varchar(254) not null,
  "name_" varchar(254) not null,
  "validity" int not null,
  "enabled" boolean not null,
  "created" varchar(40) not null,
  foreign key ("account_id") references "account_" ("id")
  on delete cascade
);

CREATE TABLE "share" (
  "id" varchar(254) not null primary key,
  "account_id" varchar(254) not null,
  "alias_id" varchar(254),
  "name_" varchar(254),
  "validity" int not null,
  "max_views" int not null,
  "password" varchar(254),
  "description" text,
  "created" varchar(40) not null,
  foreign key ("account_id") references "account_" ("id")
  on delete cascade,
  foreign key ("alias_id") references "alias_" ("id")
  on delete set null
);

CREATE TABLE "publish_share" (
  "id" varchar(254) not null primary key,
  "share_id" varchar(254) not null,
  "enabled" boolean not null,
  "views" int not null,
  "last_access" varchar(40),
  "publish_date" varchar(40) not null,
  "publish_until" varchar(40) not null,
  "created" varchar(40) not null,
  unique("share_id"),
  foreign key ("share_id") references "share" ("id")
  on delete cascade
);

CREATE INDEX "publish_share_until_idx" ON "publish_share"("publish_until");
CREATE INDEX "publish_share_date_idx" ON "publish_share"("publish_date");

CREATE TABLE "share_file" (
  "id" varchar(254) not null primary key,
  "share_id" varchar(254) not null,
  "file_id" varchar(254) not null,
  "filename" varchar(2000),
  "created" varchar(40) not null,
  "real_size" bigint not null,
  unique("share_id", "file_id"),
  foreign key ("share_id") references "share" ("id")
  on delete cascade,
  foreign key ("file_id") references "filemeta" ("id")
  on delete cascade
);
