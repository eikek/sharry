---
layout: docs
title: Migration
permalink: doc/migration
---

# {{ page.title }}

**NOTE: This migration has been available for 2 years and was removed
in version 1.10.0. Should you need it, please use a version prior to
1.10.0 to run the migration from 0.6.x. After this you can start the
newest version.**


For users of Sharry version 0.6.x, the database schema must be
migrated (kind of) manually. The application doesn't do it
automatically. However, there is a built-in script that converts the
old schema into the new one.

But: At first, please backup the data. If you don't care, then its
probably easier to just start with a new database :).

When migrating from Sharry version < 0.6.x, you'll need first to run a
0.6 version against the database. This will evolve the db schema to
the point where the migration-script from 1.0 can take it further.
Then follow this guide.

## Postgres and MariaDB

For these databases, you can start the restserver binary with a
special option `-Dsharry.migrate-old-dbschema=true`.

```
./sharry-restserver-@VERSION@/bin/sharry-restserver -Dsharry.migrate-old-dbschema=true ./sharry-new.conf
```

This will not start the restserver but rather run the migration
against the database configured in given config file.

If that completes successfully, you can startup sharry as normal
(without that option).


## H2

H2 is a little more involved. This is because the database
initialization changed and the parameters given with the URL cannot be
changed afterwards.

The steps are roughly this:

- create a dump
- change the dump to make it postgres compatible
- import it into a new database (using the new connection settings)
- run the migration from above

### Dump

The dump can be created using a tool provided by h2: `Script`
([doc](https://h2database.com/javadoc/org/h2/tools/Script.html)). It
is in the jar file that is on your disk if you have sharry installed.
So the dump can be created like this:

```
java -cp sharry-restserver-@VERSION@/lib/com.h2database.h2-1.4.200.jar org.h2.tools.Script -url "jdbc:h2:///var/data/sharry/sharry-old-db" -user sa -password ""
```

This will create a `backup.sql` file in the current directory.


### Change the Dump

This dump uses some incompatible things: all identifiers are upper
case and the datatype for a blob is called bytea in postgres. This can
be changed with GNU Sed:

```
sed -i 's,"CHUNKDATA" BLOB NOT NULL,"CHUNKDATA" BYTEA NOT NULL,g' backup.sql
sed -i 's,"[_A-Z]*",\L&,g' backup.sql
```

The first command fixes the datatype thing and the second converts all
words in quotes into lowercase.

Note: for the second command, the GNU version of Sed is required.

### Import the Dump

Now the changed dump must be imported into a new database. Since h2
creates one on demand, just run the command and specify now the new
connection – to an unexisting file and with the required settings
`MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE`. Again, a tool from h2 can be
used (`RunScript`,
[doc](https://h2database.com/javadoc/org/h2/tools/RunScript.html)):

```
java -cp sharry-restserver-@VERSION@/lib/com.h2database.h2-1.4.200.jar org.h2.tools.RunScript -url "jdbc:h2:///var/data/sharry/sharry-newdb;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE" -user sa -password ""
```

### Migrate

Now run sharry with the migration setting as described above for
Postgres and MariaDB.
