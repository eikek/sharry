import com.github.eikek.sbt.openapi._
import scala.sys.process._
import com.typesafe.sbt.SbtGit.GitKeys._


val elmCompileMode = settingKey[ElmCompileMode]("How to compile elm sources")

val sharedSettings = Seq(
  organization := "com.github.eikek",
  scalaVersion := "2.13.1",
  scalacOptions ++= Seq(
    "-deprecation",
    "-encoding", "UTF-8",
    "-language:higherKinds",
    "-language:postfixOps",
    "-feature",
    "-Xfatal-warnings", // fail when there are warnings
    "-unchecked",
    "-Xlint",
    "-Ywarn-dead-code",
    "-Ywarn-numeric-widen",
    "-Ywarn-value-discard"
  ),
  scalacOptions in (Compile, console) := Seq()
)

val testSettings = Seq(
  testFrameworks += new TestFramework("minitest.runner.Framework"),
  libraryDependencies ++= Dependencies.miniTest
)

val elmSettings = Seq(
  elmCompileMode := ElmCompileMode.Debug,
  Compile/resourceGenerators += (Def.task {
    compileElm(streams.value.log
      , (Compile/baseDirectory).value
      , (Compile/resourceManaged).value
      , name.value
      , version.value
      , elmCompileMode.value)
  }).taskValue,
  watchSources += Watched.WatchSource(
    (Compile/sourceDirectory).value/"elm"
      , FileFilter.globFilter("*.elm")
      , HiddenFileFilter
  )
)

val webjarSettings = Seq(
  Compile/resourceGenerators += (Def.task {
    copyWebjarResources(Seq((sourceDirectory in Compile).value/"webjar")
      , (Compile/resourceManaged).value
      , name.value
      , version.value
      , streams.value.log
    )
  }).taskValue,
  watchSources += Watched.WatchSource(
    (Compile / sourceDirectory).value/"webjar"
      , FileFilter.globFilter("*.js") || FileFilter.globFilter("*.css")
      , HiddenFileFilter
  )
)

val debianSettings = Seq(
  maintainer := "Eike Kettner <eike.kettner@posteo.de>",
  packageSummary := description.value,
  packageDescription := description.value,
  mappings in Universal += {
    val conf = (Compile / resourceDirectory).value / "reference.conf"
    if (!conf.exists) {
      sys.error(s"File $conf not found")
    }
    conf -> "conf/sharry.conf"
  },
  bashScriptExtraDefines += """addJava "-Dconfig.file=${app_home}/../conf/sharry.conf""""
)

val buildInfoSettings = Seq(
  buildInfoKeys := Seq[BuildInfoKey](name
    , version
    , scalaVersion
    , sbtVersion
    , gitHeadCommit
    , gitHeadCommitDate
    , gitUncommittedChanges
    , gitDescribedVersion),
  buildInfoOptions += BuildInfoOption.ToJson,
  buildInfoOptions += BuildInfoOption.BuildTime
)



val common = project.in(file("modules/common")).
  settings(sharedSettings).
  settings(testSettings).
  settings(
    name := "sharry-common",
    libraryDependencies ++=
      Dependencies.loggingApi ++
      Dependencies.fs2 ++
      Dependencies.fs2io ++
      Dependencies.circe ++
      Dependencies.pureconfig
  )

val store = project.in(file("modules/store")).
  settings(sharedSettings).
  settings(testSettings).
  settings(
    name := "sharry-store",
    libraryDependencies ++=
      Dependencies.doobie ++
      Dependencies.bitpeace ++
      Dependencies.tika ++
      Dependencies.fs2 ++
      Dependencies.databases ++
      Dependencies.flyway ++
      Dependencies.loggingApi
  ).
  dependsOn(common)

val restapi = project.in(file("modules/restapi")).
  enablePlugins(OpenApiSchema).
  settings(sharedSettings).
  settings(testSettings).
  settings(
    name := "sharry-restapi",
    libraryDependencies ++=
      Dependencies.circe,
    openapiTargetLanguage := Language.Scala,
    openapiPackage := Pkg("sharry.restapi.model"),
    openapiSpec := (Compile/resourceDirectory).value/"sharry-openapi.yml",
    openapiScalaConfig := ScalaConfig().withJson(ScalaJson.circeSemiauto).
      addMapping(CustomMapping.forType({
        case TypeDef("LocalDateTime", _)  =>
          TypeDef("Timestamp", Imports("sharry.common.Timestamp"))
      })).
      addMapping(CustomMapping.forFormatType({
        case "ident" => field =>
          field.copy(typeDef = TypeDef("Ident", Imports("sharry.common.Ident")))
        case "accountstate" => field =>
          field.copy(typeDef = TypeDef("AccountState", Imports("sharry.common.AccountState")))
        case "accountsource" => field =>
          field.copy(typeDef = TypeDef("AccountSource", Imports("sharry.common.AccountSource")))
        case "password" => field =>
          field.copy(typeDef = TypeDef("Password", Imports("sharry.common.Password")))
        case "signupmode" => field =>
          field.copy(typeDef = TypeDef("SignupMode", Imports("sharry.common.SignupMode")))
        case "uri" => field =>
          field.copy(typeDef = TypeDef("LenientUri", Imports("sharry.common.LenientUri")))
        case "duration" => field =>
          field.copy(typeDef = TypeDef("Duration", Imports("sharry.common.Duration")))
        case "size" => field =>
          field.copy(typeDef = TypeDef("ByteSize", Imports("sharry.common.ByteSize")))
      }))).
  dependsOn(common)

val backend = project.in(file("modules/backend")).
  settings(sharedSettings).
  settings(testSettings).
  settings(
    name := "sharry-backend",
    libraryDependencies ++=
      Dependencies.loggingApi ++
      Dependencies.fs2 ++
      Dependencies.bcrypt ++
      Dependencies.yamusca ++
      Dependencies.emil
  ).dependsOn(common, store)

val webapp = project.in(file("modules/webapp")).
  enablePlugins(OpenApiSchema).
  settings(sharedSettings).
  settings(elmSettings).
  settings(webjarSettings).
  settings(
    name := "sharry-webapp",
    openapiTargetLanguage := Language.Elm,
    openapiPackage := Pkg("Api.Model"),
    openapiSpec := (restapi/Compile/resourceDirectory).value/"sharry-openapi.yml",
    openapiElmConfig := ElmConfig().withJson(ElmJson.decodePipeline)
  )

val restserver = project.in(file("modules/restserver")).
  enablePlugins(BuildInfoPlugin
    , JavaServerAppPackaging
    , DebianPlugin
    , SystemdPlugin).
  settings(sharedSettings).
  settings(testSettings).
  settings(debianSettings).
  settings(buildInfoSettings).
  settings(
    name := "sharry-restserver",
    libraryDependencies ++=
      Dependencies.http4s ++
      Dependencies.http4sclient ++
      Dependencies.circe ++
      Dependencies.pureconfig ++
      Dependencies.yamusca ++
      Dependencies.webjars ++
      Dependencies.loggingApi ++
      Dependencies.logging,
    addCompilerPlugin(Dependencies.kindProjectorPlugin),
    addCompilerPlugin(Dependencies.betterMonadicFor),
    buildInfoPackage := "sharry.restserver",
    javaOptions in reStart ++=
      Seq(s"-Dconfig.file=${(LocalRootProject/baseDirectory).value/"local"/"dev.conf"}",
        "-Dsharry.migrate-old-dbschema=false",
        "-Xmx512M"),
    Compile/resourceGenerators += Def.task {
      copyWebjarResources(Seq((restapi/Compile/resourceDirectory).value/"sharry-openapi.yml")
        , (Compile/resourceManaged).value
        , name.value
        , version.value
        , streams.value.log)
    }.taskValue,
    Compile/sourceGenerators += (Def.task {
      createWebjarSource(Dependencies.webjars, (Compile/sourceManaged).value)
    }).taskValue,
    Compile/unmanagedResourceDirectories ++= Seq((Compile/resourceDirectory).value.getParentFile/"templates")
  ).dependsOn(restapi, backend, webapp)

lazy val microsite = project.in(file("modules/microsite")).
  enablePlugins(MicrositesPlugin).
  disablePlugins(ReleasePlugin).
  settings(sharedSettings).
  settings(
    name := "sharry-microsite",
    publishArtifact := false,
    skip in publish := true,
    micrositeFooterText := Some(
      """
        |<p>&copy; 2020 <a href="https://eikek.github.io/sharry">Sharry, v{{site.version}}</a></p>
        |""".stripMargin
    ),
    micrositeName := "Sharry",
    micrositeDescription := "Sharry – Share files conveniently",
    micrositeDocumentationUrl := "/sharry/doc/index.html",
    micrositeFavicons := Seq(microsites.MicrositeFavicon("favicon-32x32.png", "32x32")),
    micrositeBaseUrl := "/sharry",
    micrositeAuthor := "eikek",
    micrositeGithubOwner := "eikek",
    micrositeGithubRepo := "sharry",
    micrositeGitterChannel := false,
    micrositeShareOnSocial := false,
    micrositePalette := Map(
        "brand-primary"         -> "#7a1800",
        "brand-secondary"       -> "#009ADA",
        "white-color"           -> "#FFFFFF"),
    fork in run := true,
    micrositeCompilingDocsTool := WithMdoc,
    mdocVariables := Map(
      "VERSION" -> version.value,
      "PVERSION" -> version.value.replace('.', '_')
    ),
    Compile / resourceGenerators += Def.task {
      val conf1 = (resourceDirectory in (restserver, Compile)).value / "reference.conf"
      val out1 = resourceManaged.value/"main"/"jekyll"/"_includes"/"server.conf"
      streams.value.log.info(s"Copying reference.conf: $conf1 -> $out1")
      IO.write(out1, "{% raw %}\n")
      IO.append(out1, IO.readBytes(conf1))
      IO.write(out1, "\n{% endraw %}", append = true)
      val oa1 = (resourceDirectory in (restapi, Compile)).value/"sharry-openapi.yml"
      val oaout = resourceManaged.value/"main"/"jekyll"/"openapi"/"sharry-openapi.yml"
      IO.copy(Seq(oa1 -> oaout))
      Seq(out1, oaout)
    }.taskValue,
    Compile / resourceGenerators += Def.task {
      val staticDoc = (restapi/Compile/openapiStaticDoc).value
      val target = resourceManaged.value/"main"/"jekyll"/"openapi"/"sharry-openapi.html"
      streams.value.log.info(s"Copy $staticDoc -> $target")
      IO.copy(Seq(staticDoc -> target))
      Seq(target)
    }.taskValue
  )


val root = project.in(file(".")).
  settings(sharedSettings).
  settings(
    name := "sharry-root"
  ).
  aggregate(common, store, backend, webapp, restapi, restserver)


def copyWebjarResources(src: Seq[File], base: File, artifact: String, version: String, logger: Logger): Seq[File] = {
  val targetDir = base/"META-INF"/"resources"/"webjars"/artifact/version
  src.flatMap { dir =>
    if (dir.isDirectory) {
      val files = (dir ** "*").filter(_.isFile).get pair Path.relativeTo(dir)
      files.map { case (f, name) =>
        val target = targetDir/name
        logger.info(s"Copy $f -> $target")
        IO.createDirectories(Seq(target.getParentFile))
        IO.copy(Seq(f -> target))
        target
      }
    } else {
      val target = targetDir/dir.name
      logger.info(s"Copy $dir -> $target")
      IO.createDirectories(Seq(target.getParentFile))
      IO.copy(Seq(dir -> target))
      Seq(target)
    }
  }
}

def compileElm(logger: Logger, wd: File, outBase: File, artifact: String, version: String, mode: ElmCompileMode): Seq[File] = {
  logger.info("Compile elm files ...")
  val target = outBase/"META-INF"/"resources"/"webjars"/artifact/version/"sharry-app.js"
  val cmd = Seq("elm", "make") ++ mode.flags ++ Seq("--output", target.toString)
  val proc = Process(cmd ++ Seq(wd/"src"/"main"/"elm"/"Main.elm").map(_.toString), Some(wd))
  val out = proc.!!
  logger.info(out)
  Seq(target)
}

def createWebjarSource(wj: Seq[ModuleID], out: File): Seq[File] = {
  val target = out/"Webjars.scala"
  val fields = wj.map(m => s"""val ${m.name.toLowerCase.filter(_ != '-')} = "/${m.name}/${m.revision}" """).mkString("\n\n")
  val content = s"""package sharry.restserver.webapp
    |object Webjars {
    |$fields
    |}
    |""".stripMargin

  IO.write(target, content)
  Seq(target)
}

addCommandAlias("make", ";set webapp/elmCompileMode := ElmCompileMode.Production ;root/openapiCodegen ;root/test:compile")
addCommandAlias("make-zip", ";restserver/universal:packageBin")
addCommandAlias("make-deb", ";restserver/debian:packageBin")
addCommandAlias("make-pkg", ";clean ;make ;make-zip ;make-deb")
