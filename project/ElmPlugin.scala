package sharry.build

import sbt._
import sbt.Keys._
import java.nio.file._
import scala.util.{Failure, Success, Try}
import com.google.javascript.jscomp.CommandLineRunner

object ElmPlugin extends AutoPlugin {

  object autoImport {
    val elmMakeExecuteable = settingKey[String]("The executable `elm-make'")
    val elmTestExecuteable = settingKey[String]("The executable `elm-test'")
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
    val elmProject = taskKey[Seq[File]]("Create elm-package.json")
    val elmMake = taskKey[Seq[File]]("Compile elm files")
    val elmTest = taskKey[Seq[File]]("Run elm tests using elm-test")
    val elmReactor = taskKey[Unit]("Run `elm-reactor'")
  }

  import autoImport._

  lazy val elmSettings = Seq(
    elmMakeExecuteable := "elm-make",
    elmTestExecuteable := "elm-test",
    elmReactorExecuteable := "elm-reactor",
    elmReactorPort := 8000,
    elmMakeOutputPath := (resourceManaged in Compile).value/"META-INF"/"resources"/"webjars"/(name in Compile).value/(version in Compile).value,
    elmSources := (sourceDirectory in Compile).value/"elm",
    elmSources in Test := (sourceDirectory in Test).value/"elm",
    elmDebug := false,
    elmMinify := false,
    elmGithubRepo := (homepage.value match {
      case Some(url) if url.toString.startsWith("https://github.com") => url.toString
      case _ => "https://github.com/user/repo.git"
    }),
    elmDependencies := Seq.empty,
    elmDependencies in Test := (elmDependencies in Compile).value,
    elmWd := (target in Compile).value/"elm-make",
    elmMakeCompilationLevel := "SIMPLE",
    elmProject := {
      val wd = elmWd.value
      IO.createDirectories(Seq(wd))
      if (!Files.exists((wd/elmSources.value.getName).toPath) && Files.exists(elmSources.value.toPath)) {
        Files.createSymbolicLink((wd/elmSources.value.getName).toPath, elmSources.value.toPath)
      }
      val pkgJson = wd/"elm-package.json"
      val content = packageJson(elmDependencies, false).value
      if (!pkgJson.exists || Hash.toHex(Hash(pkgJson)) != Hash.toHex(Hash(content))) {
        streams.value.log.info("Generating elm-package.json")
        IO.write(pkgJson, content)
      }

      val testPkgJson = wd/"tests"/"elm-package.json"
      val testContent = packageJson(elmDependencies in Test, true).value
      if (!testPkgJson.exists || Hash.toHex(Hash(testPkgJson)) != Hash.toHex(Hash(testContent))) {
        streams.value.log.info("Generating tests/elm-package.json")
        IO.write(testPkgJson, testContent)
      }
      if (!Files.exists((wd/"tests"/(elmSources in Test).value.getName).toPath) && Files.exists((elmSources in Test).value.toPath)) {
        Files.createSymbolicLink((wd/"tests"/(elmSources in Test).value.getName).toPath, (elmSources in Test).value.toPath)
      }

      Seq(pkgJson, testPkgJson)
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
    elmTest := {
      val wd = elmWd.value
      val proc = Process(elmTestExecuteable.value, Some(wd))
      runCmd(proc, streams.value.log,
        "Elm tests successful",
        "Elm tests failed")
      val out = wd/"elm-stuff"/"generated-code"/"elm-community"/"elm-test"/"elmTestOutput.js"
      if (out.exists) Seq(out) else Seq.empty[File]
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
      watchSources ++= ((elmSources in Compile).value ** ("*.elm")).get ++ ((elmSources in Test).value ** ("*.elm")).get
    )


  def packageJson(deps: SettingKey[Seq[(String, String)]], test: Boolean) = Def.task {
    val sources =
      if (!test) Seq((elmSources in Compile).value.getName)
      else Seq((elmSources in Test).value.getName, "../"+ (elmSources in Compile).value.getName)

    s"""{
    |  "version" : "${version.value.replaceAll("[^0-9\\.]", "")}",
    |  "summary" : "${description.value}",
    |  "repository" : "${elmGithubRepo.value}",
    |  "license" : "",
    |  "source-directories" : [
    |    ${sources.mkString("\"", "\", \"", "\"")}
    |  ],
    |  "exposed-modules" : [],
    |  "dependencies" : {
    |    ${deps.value.map({case (k,v) => "\""+k+"\" : \""+v+"\"" }).mkString(",\n    ")}
    |  },
    |  "elm-version" : "${elmVersion.value}"
    |}""".stripMargin
  }


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
