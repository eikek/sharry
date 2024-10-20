import sbt._

object Dependencies {

  val BcryptVersion = "0.4"
  val BetterMonadicForVersion = "0.3.1"
  val BinnyVersion = "0.11.0"
  val CirceVersion = "0.14.10"
  val CirisVersion = "3.6.0"
  val ClipboardJsVersion = "2.0.11"
  val DoobieVersion = "1.0.0-RC6"
  val EmilVersion = "0.17.0"
  val FlywayVersion = "10.20.0"
  val Fs2Version = "3.11.0"
  val H2Version = "2.3.232"
  val Http4sVersion = "0.23.28"
  val JQueryVersion = "3.5.1"
  val KindProjectorVersion = "0.10.3"
  val MariaDbVersion = "3.4.1"
  val MUnitVersion = "1.0.0"
  val MUnitCatsEffectVersion = "2.0.0"
  val PostgresVersion = "42.7.4"
  val ScribeVersion = "3.15.1"
  val SourcecodeVersion = "0.4.2"
  val SwaggerVersion = "5.17.14"
  val TikaVersion = "2.9.2"
  val TusClientVersion = "1.8.0-1"
  val TypesafeConfigVersion = "1.4.3"
  val YamuscaVersion = "0.10.0"

  val ciris = Seq(
    "is.cir" %% "ciris" % CirisVersion
  )
  val typesafeConfig = Seq(
    "com.typesafe" % "config" % TypesafeConfigVersion
  )

  val scribe = Seq(
    "com.outr" %% "scribe" % ScribeVersion,
    "com.outr" %% "scribe-slf4j2" % ScribeVersion,
    "com.outr" %% "scribe-cats" % ScribeVersion,
    "com.outr" %% "scribe-json-circe" % ScribeVersion
  )

  val sourcecode = Seq(
    "com.lihaoyi" %% "sourcecode" % SourcecodeVersion
  )

  val fs2 = Seq(
    "co.fs2" %% "fs2-core" % Fs2Version
  )
  val fs2io = Seq(
    "co.fs2" %% "fs2-io" % Fs2Version
  )

  val tika = Seq(
    "org.apache.tika" % "tika-core" % TikaVersion
  )

  val http4s = Seq(
    "org.http4s" %% "http4s-ember-server" % Http4sVersion,
    "org.http4s" %% "http4s-circe" % Http4sVersion,
    "org.http4s" %% "http4s-dsl" % Http4sVersion
  )

  val http4sclient = Seq(
    "org.http4s" %% "http4s-dsl" % Http4sVersion,
    "org.http4s" %% "http4s-ember-client" % Http4sVersion
  )

  val circeCore = Seq(
    "io.circe" %% "circe-core" % CirceVersion
  )
  val circe = Seq(
    "io.circe" %% "circe-generic" % CirceVersion,
    "io.circe" %% "circe-parser" % CirceVersion
  )

  // https://github.com/h2database/h2database
  // MPL 2.0 or EPL 1.0
  val h2 = Seq(
    "com.h2database" % "h2" % H2Version
  )
  val mariadb = Seq(
    "org.mariadb.jdbc" % "mariadb-java-client" % MariaDbVersion
  )
  val postgres = Seq(
    "org.postgresql" % "postgresql" % PostgresVersion
  )
  val databases = h2 ++ mariadb ++ postgres

  // https://github.com/tpolecat/doobie
  // MIT
  val doobie = Seq(
    "org.tpolecat" %% "doobie-core" % DoobieVersion,
    "org.tpolecat" %% "doobie-hikari" % DoobieVersion
  )

  val binny = Seq(
    "com.github.eikek" %% "binny-core" % BinnyVersion,
    "com.github.eikek" %% "binny-jdbc" % BinnyVersion,
    "com.github.eikek" %% "binny-minio" % BinnyVersion,
    "com.github.eikek" %% "binny-fs" % BinnyVersion,
    "com.github.eikek" %% "binny-tika-detect" % BinnyVersion
  )

  val emil = Seq(
    "com.github.eikek" %% "emil-common" % EmilVersion,
    "com.github.eikek" %% "emil-javamail" % EmilVersion
  )

  // https://github.com/flyway/flyway
  // ASL 2.0
  val flyway = Seq(
    "org.flywaydb" % "flyway-core" % FlywayVersion,
    "org.flywaydb" % "flyway-mysql" % FlywayVersion,
    "org.flywaydb" % "flyway-database-postgresql" % FlywayVersion
  )

  val yamusca = Seq(
    "com.github.eikek" %% "yamusca-core" % YamuscaVersion,
    "com.github.eikek" %% "yamusca-derive" % YamuscaVersion
  )

  val bcrypt = Seq(
    "org.mindrot" % "jbcrypt" % BcryptVersion
  )

  val munit = Seq(
    "org.scalameta" %% "munit" % MUnitVersion,
    "org.scalameta" %% "munit-scalacheck" % MUnitVersion,
    "org.typelevel" %% "munit-cats-effect" % MUnitCatsEffectVersion
  )

  val kindProjectorPlugin = "org.typelevel" %% "kind-projector" % KindProjectorVersion
  val betterMonadicFor = "com.olegpy" %% "better-monadic-for" % BetterMonadicForVersion

  val webjars = Seq(
    "org.webjars" % "swagger-ui" % SwaggerVersion,
    "org.webjars.npm" % "tus-js-client" % TusClientVersion,
    "org.webjars" % "clipboard.js" % ClipboardJsVersion
  )
}
