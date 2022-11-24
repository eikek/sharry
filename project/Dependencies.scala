import sbt._

object Dependencies {

  val BcryptVersion = "0.4"
  val BetterMonadicForVersion = "0.3.1"
  val BinnyVersion = "0.7.0"
  val CirceVersion = "0.14.3"
  val ClipboardJsVersion = "2.0.6"
  val DoobieVersion = "1.0.0-RC2"
  val EmilVersion = "0.13.0"
  val FlywayVersion = "9.8.3"
  val Fs2Version = "3.4.0"
  val H2Version = "2.1.214"
  val Http4sVersion = "0.23.16"
  val JQueryVersion = "3.5.1"
  val KindProjectorVersion = "0.10.3"
  val MariaDbVersion = "3.1.0"
  val MUnitVersion = "0.7.29"
  val OrganizeImportsVersion = "0.6.0"
  val PostgresVersion = "42.5.1"
  val PureConfigVersion = "0.17.2"
  val ScribeVersion = "3.9.0"
  val SourcecodeVersion = "0.2.8"
  val SwaggerVersion = "4.15.5"
  val TikaVersion = "2.6.0"
  val TusClientVersion = "1.8.0-1"
  val YamuscaVersion = "0.10.0"

  val scribe = Seq(
    "com.outr" %% "scribe" % ScribeVersion,
    "com.outr" %% "scribe-slf4j" % ScribeVersion
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
    "org.http4s" %% "http4s-blaze-server" % "0.23.12",
    "org.http4s" %% "http4s-circe" % Http4sVersion,
    "org.http4s" %% "http4s-dsl" % Http4sVersion
  )

  val http4sclient = Seq(
    "org.http4s" %% "http4s-dsl" % Http4sVersion,
    "org.http4s" %% "http4s-blaze-client" % "0.23.12"
  )

  val circeCore = Seq(
    "io.circe" %% "circe-core" % CirceVersion
  )
  val circe = Seq(
    "io.circe" %% "circe-generic" % CirceVersion,
    "io.circe" %% "circe-parser" % CirceVersion
  )

  // https://github.com/melrief/pureconfig
  // MPL 2.0
  val pureconfig = Seq(
    "com.github.pureconfig" %% "pureconfig" % PureConfigVersion
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
    "org.flywaydb" % "flyway-mysql" % FlywayVersion
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
    "org.scalameta" %% "munit-scalacheck" % MUnitVersion
  )

  val kindProjectorPlugin = "org.typelevel" %% "kind-projector" % KindProjectorVersion
  val betterMonadicFor = "com.olegpy" %% "better-monadic-for" % BetterMonadicForVersion

  val webjars = Seq(
    "org.webjars" % "swagger-ui" % SwaggerVersion,
    "org.webjars.npm" % "tus-js-client" % TusClientVersion,
    "org.webjars" % "clipboard.js" % ClipboardJsVersion
  )

  val organizeImports = Seq(
    "com.github.liancheng" %% "organize-imports" % OrganizeImportsVersion
  )

}
