import sbt._

object Dependencies {

  val BcryptVersion           = "0.4"
  val BetterMonadicForVersion = "0.3.1"
  val BitpeaceVersion         = "0.7.0"
  val CirceVersion            = "0.13.0"
  val ClipboardJsVersion      = "2.0.6"
  val DoobieVersion           = "0.13.1"
  val EmilVersion             = "0.9.1"
  val FlywayVersion           = "7.8.2"
  val FomanticUIVersion       = "2.8.7-3"
  val Fs2Version              = "2.5.5"
  val H2Version               = "1.4.200"
  val Http4sVersion           = "0.21.22"
  val JQueryVersion           = "3.5.1"
  val KindProjectorVersion    = "0.10.3"
  val Log4sVersion            = "1.9.0"
  val LogbackVersion          = "1.2.3"
  val MariaDbVersion          = "2.7.2"
  val MiniTestVersion         = "2.9.4"
  val MUnitVersion            = "0.7.25"
  val OrganizeImportsVersion  = "0.5.0"
  val PostgresVersion         = "42.2.20"
  val PureConfigVersion       = "0.15.0"
  val SwaggerVersion          = "3.48.0"
  val TikaVersion             = "1.26"
  val TusClientVersion        = "1.8.0-1"
  val YamuscaVersion          = "0.8.0"

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
    "org.http4s" %% "http4s-blaze-server" % Http4sVersion,
    "org.http4s" %% "http4s-circe"        % Http4sVersion,
    "org.http4s" %% "http4s-dsl"          % Http4sVersion
  )

  val http4sclient = Seq(
    "org.http4s" %% "http4s-dsl"          % Http4sVersion,
    "org.http4s" %% "http4s-blaze-client" % Http4sVersion
  )

  val circe = Seq(
    "io.circe" %% "circe-generic" % CirceVersion,
    "io.circe" %% "circe-parser"  % CirceVersion
  )

  // https://github.com/Log4s/log4s;ASL 2.0
  val loggingApi = Seq(
    "org.log4s" %% "log4s" % Log4sVersion
  )

  val logging = Seq(
    "ch.qos.logback" % "logback-classic" % LogbackVersion % Runtime
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
    "org.tpolecat" %% "doobie-core"   % DoobieVersion,
    "org.tpolecat" %% "doobie-hikari" % DoobieVersion
  )

  val bitpeace = Seq(
    "com.github.eikek" %% "bitpeace-core" % BitpeaceVersion
  )

  val emil = Seq(
    "com.github.eikek" %% "emil-common"   % EmilVersion,
    "com.github.eikek" %% "emil-javamail" % EmilVersion
  )

  // https://github.com/flyway/flyway
  // ASL 2.0
  val flyway = Seq(
    "org.flywaydb" % "flyway-core" % FlywayVersion
  )

  val yamusca = Seq(
    "com.github.eikek" %% "yamusca-core" % YamuscaVersion
  )

  val bcrypt = Seq(
    "org.mindrot" % "jbcrypt" % BcryptVersion
  )

  val miniTest = Seq(
    // https://github.com/monix/minitest
    // Apache 2.0
    "io.monix" %% "minitest"      % MiniTestVersion,
    "io.monix" %% "minitest-laws" % MiniTestVersion
  ).map(_ % Test)

  val munit = Seq(
    "org.scalameta" %% "munit"            % MUnitVersion,
    "org.scalameta" %% "munit-scalacheck" % MUnitVersion
  )

  val kindProjectorPlugin = "org.typelevel" %% "kind-projector"     % KindProjectorVersion
  val betterMonadicFor    = "com.olegpy"    %% "better-monadic-for" % BetterMonadicForVersion

  val webjars = Seq(
    "org.webjars"      % "swagger-ui"            % SwaggerVersion,
    "com.github.eikek" % "fomantic-slim-default" % FomanticUIVersion,
    "org.webjars.npm"  % "tus-js-client"         % TusClientVersion,
    "org.webjars"      % "clipboard.js"          % ClipboardJsVersion
  )

  val organizeImports = Seq(
    "com.github.liancheng" %% "organize-imports" % OrganizeImportsVersion
  )

}
