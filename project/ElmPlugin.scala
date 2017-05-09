package sharry.build

import sbt._
import sbt.Keys._
import java.nio.file._
import scala.util.{Failure, Success, Try}
import com.google.javascript.jscomp.CommandLineRunner

object ElmPlugin extends AutoPlugin {

  object autoImport {
    val elmMakeExecuteable = settingKey[String]("The executable `elm-make'")
    val elmMakeOutputPath = settingKey[File]("The directory to store elm-make output")
    val elmDependencies = settingKey[Seq[(String, String)]]("Elm package dependencies")
    val elmSources = settingKey[File]("Directory to scan for elm files")
    val elmVersion = settingKey[String]("The version (range) for elm language")
    val elmDebug = settingKey[Boolean]("Whether to use --debug with `elm-make'")
    val elmWd = settingKey[File]("Working directory for elm-make")
    val elmGithubRepo = settingKey[String]("Github url to elm package (required in elm-package.json)")
    val elmReactorExecuteable = settingKey[String]("Executeable for `elm-reactor'")
    val elmReactorPort = settingKey[Int]("The port for elm-reactor")
    val elmMakeCompilationLevel = settingKey[String]("The compilation level passed to google closure compiler. One of WHITESPACE_ONLY, SIMPLE or ADVANCED")
    val elmMinify = settingKey[Boolean]("Whether to run minifier after compilation")
    val elmProject = taskKey[File]("Create elm-package.json")
    val elmMake = taskKey[Seq[File]]("Compile elm files")
    val elmReactor = taskKey[Unit]("Run `elm-reactor'")
  }

  import autoImport._

  lazy val elmSettings = Seq(
    elmMakeExecuteable := "elm-make",
    elmReactorExecuteable := "elm-reactor",
    elmReactorPort := 8000,
    elmMakeOutputPath := (resourceManaged in Compile).value/"META-INF"/"resources"/"webjars"/(name in Compile).value/(version in Compile).value,
    elmSources := (sourceDirectory in Compile).value/"elm",
    elmDebug := false,
    elmMinify := false,
    elmGithubRepo := (homepage.value match {
      case Some(url) if url.toString.startsWith("https://github.com") => url.toString
      case _ => "https://github.com/user/repo.git"
    }),
    elmDependencies := Seq.empty,
    elmWd := (target in Compile).value/"elm-make",
    elmMakeCompilationLevel := "SIMPLE",
    elmProject := {
      val wd = elmWd.value
      IO.createDirectories(Seq(wd))
      if (!Files.exists((wd/elmSources.value.getName).toPath) && Files.exists(elmSources.value.toPath)) {
        Files.createSymbolicLink((wd/elmSources.value.getName).toPath, elmSources.value.toPath)
      }
      val pkgJson = wd/"elm-package.json"
      val content = s"""{
      |  "version" : "${version.value.replaceAll("[^0-9\\.]", "")}",
      |  "summary" : "${description.value}",
      |  "repository" : "${elmGithubRepo.value}",
      |  "license" : "",
      |  "source-directories" : [
      |    "${elmSources.value.getName}"
      |  ],
      |  "exposed-modules" : [],
      |  "dependencies" : {
      |    ${elmDependencies.value.map({case (k,v) => "\""+k+"\" : \""+v+"\"" }).mkString(",\n    ")}
      |  },
      |  "elm-version" : "${elmVersion.value}"
      |}""".stripMargin
      if (!pkgJson.exists || Hash.toHex(Hash(pkgJson)) != Hash.toHex(Hash(content))) {
        streams.value.log.info("Generating elm-package.json")
        IO.write(pkgJson, content)
      }
      pkgJson
    },
    elmMake := {
      val pkg = elmProject.value
      val wd = elmWd.value
      // need to check all files whether to decide for recompile
      val allFiles: Seq[File] = sbt.Path.allSubpaths(elmSources.value).
        map(_._1).
        filter(_.getName.endsWith(".elm")).
        toSeq
      val filesToCompile = IO.listFiles(elmSources.value, GlobFilter("*.elm")).
        map(f => elmSources.value.getName + java.io.File.separator + f.getName)
      if (allFiles.isEmpty) {
        streams.value.log.info("No elm source files found.")
        Seq.empty
      } else {
        val newest = allFiles.sortBy(-_.lastModified).head
        val out = elmMakeOutputPath.value/"elm-main.js"
        val minified = elmMakeOutputPath.value/"elm-main.min.js"
        if (!out.exists || newest.lastModified >= out.lastModified) {
          streams.value.log.info(s"Compiling ${filesToCompile.size} elm files …")
          IO.delete(Seq(out, minified))
          val opts: Seq[String] = if (elmDebug.value) Seq("--debug", "--yes") else Seq("--yes")
          val proc = Process(elmMakeExecuteable.value +: (filesToCompile ++ opts ++ Seq("--output", out.toString)), Some(wd))
          runCmd(proc, streams.value.log,
            "Elm files compiled successfully",
            "Error compiling elm files")
          if (elmMinify.value) {
            streams.value.log.info("Running Closure compiler…")
            val clrun = new Minify("--compilation_level", elmMakeCompilationLevel.value, "--js", out.toString, "--js_output_file", minified.toString)
            clrun.compile()
            IO.move(minified, out)
          }
        } else {
          streams.value.log.info("Elm files are up to date")
        }
        Seq(out)
      }
    },
    elmReactor := {
      val pkg = elmProject.value
      val wd = elmWd.value
      val proc = Process(Seq(elmReactorExecuteable.value, "-p", elmReactorPort.value.toString), Some(wd))
      runCmd(proc, streams.value.log,
        "Started elm-reactor",
        "Unable to start elm-reactor")
    }
  )

  override def projectSettings =
    inConfig(Compile)(elmSettings) ++ Seq(
      watchSources ++= ((elmSources in Compile).value ** ("*.elm")).get
    )


  def runCmd(proc: ProcessBuilder, log: Logger, success: String, error: String): Unit = {
    val logger = new ProcLogger(log)
    Try({
      val rc = proc ! logger
      if (rc != 0) sys.error("Non-zero return value")
    }) match {
      case Success(_) =>
        log.info(success)
      case Failure(ex) =>
        throw new Exception(s"$error: ${ex.getMessage}", ex)
    }
  }

  final class ProcLogger(log: Logger) extends ProcessLogger {
    def buffer[T](f: => T): T = f
    def error(s: => String): Unit = {
      log.error(s)
    }
    def info(s: => String): Unit = {
      log.info(s)
    }
  }

  final class Minify(args: String*) extends CommandLineRunner(args.toArray) {
    def compile() = doRun()
  }
}
