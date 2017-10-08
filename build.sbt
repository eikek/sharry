import libs._
import Path.relativeTo
import java.nio.file.{Files, StandardCopyOption}
import org.apache.tika.Tika
import com.typesafe.sbt.SbtGit.GitKeys._

lazy val sharedSettings = Seq(
  name := "sharry",
  scalaVersion := `scala-version`,
  scalacOptions ++= Seq(
    "-encoding", "UTF-8",
    "-Xfatal-warnings", // fail when there are warnings
    "-deprecation",
    "-feature",
    "-unchecked",
    "-language:higherKinds",
    "-Xlint",
    "-Yno-adapted-args",
    "-Ywarn-dead-code",
    "-Ywarn-numeric-widen",
    "-Ywarn-unused-import"
  ),
  scalacOptions in (Compile, console) ~= (_ filterNot (Set("-Xfatal-warnings", "-Ywarn-unused-import").contains)),
  scalacOptions in (Test) := (scalacOptions in (Compile, console)).value
)

lazy val coreDeps = Seq(`cats-core`, `fs2-core`, `fs2-io`, log4s, `scodec-bits`)
lazy val testDeps = Seq(scalatest, `logback-classic`).map(_ % "test")

lazy val common = project.in(file("modules/common")).
  enablePlugins(BuildInfoPlugin).
  disablePlugins(AssemblyPlugin).
  settings(sharedSettings).
  settings(Seq(
    name := "sharry-common",
    description := "Some common utility code",
    libraryDependencies ++= coreDeps ++ testDeps,
    buildInfoKeys := Seq[BuildInfoKey](name, version, scalaVersion, sbtVersion, gitHeadCommit, gitHeadCommitDate, gitUncommittedChanges, gitDescribedVersion),
    buildInfoPackage := "sharry.common",
    buildInfoOptions += BuildInfoOption.ToJson,
    buildInfoOptions += BuildInfoOption.BuildTime
  ))

lazy val mdutil = project.in(file("modules/mdutil")).
  settings(sharedSettings).
  settings(
    name := "sharry-mdutil",
    description := "Markdown utility for sharry based on flexmark-java",
    libraryDependencies ++= testDeps ++ coreDeps ++ Seq(
      `flexmark-core`,  `flexmark-gfm-tables`,  `flexmark-gfm-strikethrough`,
      `flexmark-formatter`, jsoup
    ))

lazy val store = project.in(file("modules/store")).
  disablePlugins(AssemblyPlugin).
  settings(sharedSettings).
  settings(Seq(
    name := "sharry-store",
    description := "Storage for files and account data",
    libraryDependencies ++= testDeps ++ coreDeps ++ Seq(
      `doobie-core`, h2, postgres, tika, `scodec-bits`, `scala-bcrypt`
    ))).
  dependsOn(common % "compile->compile;test->test")


// resumable.js is too old as webjar, so download it from github
lazy val fetchResumableJs = Def.task {
  val dir = (target in Compile).value
  val url = new java.net.URL("https://raw.githubusercontent.com/23/resumable.js/feb33c8f8d5d614d3d476fc2b3e82372c7b6408a/resumable.js")
  val outFile = dir / "resumable.js"
  val logger = streams.value.log
  if (!outFile.exists) {
    logger.info(s"Downloading $url -> ${outFile.getName} …")
    val conn = url.openConnection()
    conn.connect()
    val inStream = conn.getInputStream
    IO.createDirectories(Seq(outFile.getParentFile))
    Files.copy(inStream, outFile.toPath, StandardCopyOption.REPLACE_EXISTING)
    inStream.close
  }

  Seq(outFile -> outFile.getName)
}

lazy val webapp = project.in(file("modules/webapp")).
  enablePlugins(WebjarPlugin, ElmPlugin).
  disablePlugins(AssemblyPlugin).
  settings(sharedSettings).
  settings(Seq(
    name := "sharry-webapp",
    description := "A web frontend for sharry",
    libraryDependencies ++= testDeps ++ coreDeps ++ Seq(
      `semantic-ui`, jquery, highlightjs, `logback-classic`, yamusca,
      `circe-core`, `circe-generic`, `circe-parser`, `fs2-http`, `spinoco-http`
    ),
    // elm stuff
    elmVersion := "0.18.0 <= v < 0.19.0",
    elmDependencies in Compile ++= Seq(
      "elm-lang/core" -> "5.0.0 <= v < 6.0.0",
      "elm-lang/html" -> "2.0.0 <= v < 3.0.0",
      "elm-lang/http" -> "1.0.0 <= v < 2.0.0",
      "elm-lang/animation-frame" -> "1.0.0 <= v < 2.0.0",
      "elm-lang/navigation" -> "2.0.0 <= v < 3.0.0",
      "evancz/elm-markdown" -> "3.0.0 <= v < 4.0.0",
      "NoRedInk/elm-decode-pipeline" -> "3.0.0 <= v < 4.0.0"
    ),
    elmDependencies in Test ++= Seq(
      "elm-community/elm-test" -> "4.0.0 <= v < 5.0.0"
    ),
    // webjar stuff
    resourceGenerators in Compile += (elmMake in Compile).taskValue,
    webjarPackage in (Compile, webjarSource) := "sharry.webapp.route",
    sourceGenerators in Compile += (webjarSource in Compile).taskValue,
    resourceGenerators in Compile += (webjarContents in Compile).taskValue,
    webjarWebPackages in Compile += Def.task({
      val elmFiles = (elmMake in Compile).value pair relativeTo((elmMakeOutputPath in Compile).value)
      val src = (sourceDirectory in Compile).value
      val htmlFiles = (src/"html" ** "*").get.filter(_.isFile).toSeq pair relativeTo(src/"html")
      val cssFiles = IO.listFiles(src/"css").toSeq pair relativeTo(src/"css")
      val jsFiles = IO.listFiles(src/"js").toSeq pair relativeTo(src/"js")
      val resumable = fetchResumableJs.value
      WebPackage("org.webjars", name.value, version.value, elmFiles ++ htmlFiles ++ cssFiles ++ jsFiles ++ resumable)
    }).taskValue,
    resourceGenerators in Compile += (webjarWebPackageResources in Compile).taskValue))

lazy val docs = project.in(file("modules/docs")).
  settings(sharedSettings).
  settings(
    name := "sharry-docs",
    libraryDependencies ++= coreDeps ++ Seq(yamusca, `fs2-http`, `spinoco-http`),
    sourceGenerators in Compile += (Def.task {
      val docdir = (baseDirectory in LocalRootProject).value/"docs"
      val tika = new Tika()
      val list = sbt.Path.allSubpaths(docdir).toList.map {
        case (file, path) =>
          val checksum = Hash.toHex(Hash(file))
          (path, checksum, tika.detect(file), file.length)
      }

      val code = s"""package sharry.docs.md
           |object toc extends TocAccess {
           | val contents: List[(String, String, String, Long)] = ${list.map(t => "(\""+t._1+"\",\""+ t._2+"\", \""+t._3+"\", "+t._4+")")}
           |}""".stripMargin

      val tocFile = (sourceManaged in Compile).value/"toc.scala"
      IO.write(tocFile, code)
      Seq(tocFile)
    }).taskValue,
    resourceGenerators in Compile += (Def.task {
      val docdir = (baseDirectory in LocalRootProject).value/"docs"
      val target = (resourceManaged in Compile).value/"sharry"/"docs"/"md"
      sbt.Path.allSubpaths(docdir).toSeq.map {
        case (file, path) =>
          val targetFile = target/path
          IO.copy(Seq((file, targetFile)))
          targetFile
      }
    }).taskValue
  ).
  dependsOn(mdutil)

lazy val server = project.in(file("modules/server")).
  settings(sharedSettings).
  settings(
    name := "sharry-server",
    description := "The sharry application as a rest server",
    libraryDependencies ++= testDeps ++ coreDeps ++ Seq(
      `logback-classic`, `circe-core`, `circe-generic`, `circe-parser`,
      pureconfig, `scala-bcrypt`, `fs2-http`, `spinoco-http`, `doobie-hikari`,
      `javax-mail`, `javax-mail-api`, dnsjava, yamusca
    ),
    assemblyJarName in assembly := s"sharry-server-${version.value}.jar.sh",
    assemblyOption in assembly := (assemblyOption in assembly).value.copy(
      prependShellScript = Some(
        Seq("#!/usr/bin/env sh", """exec java -jar -XX:+UseG1GC $SHARRY_JAVA_OPTS "$0" "$@"""" + "\n")
      )
    ),
    fork in run := true,
    connectInput in run := true,
    javaOptions in run ++= Seq(
      "-Dsharry.console=true",
      "-Dsharry.authc.extern.admin.enable=true",
      "-Dsharry.db.url=jdbc:h2:./target/sharry-db.h2",
      "-Dsharry.optionalConfig=" + ((baseDirectory in LocalRootProject).value / "dev.conf")
    )
  ).
  dependsOn(common % "compile->compile;test->test", store, webapp, docs)


lazy val root = project.in(file(".")).
  disablePlugins(AssemblyPlugin).
  settings(sharedSettings).
  aggregate(common, mdutil, store, server, webapp)

addCommandAlias("run-sharry", ";project server;run")
addCommandAlias("make", ";project server ;set elmMinify in (webapp, Compile) := true ;assembly")
addCommandAlias("run-all-tests", ";test ;elmTest")
