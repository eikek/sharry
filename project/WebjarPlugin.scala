package sharry.build

import sbt._
import sbt.Keys._
import scala.collection.JavaConverters._
import scala.util.Try
import org.apache.tika.Tika
import java.io.FileInputStream
import java.util.zip.ZipInputStream
import java.net.{URI, URLEncoder}
import java.util.{HashMap => JMap}
import java.time.Instant
import _root_.io.circe._, _root_.io.circe.generic.auto._, _root_.io.circe.syntax._

object WebjarPlugin extends AutoPlugin {

  object autoImport {
    val webjarSource = taskKey[Seq[File]]("Creates a scala source file listing the webjars")
    val webjarContents = taskKey[Seq[File]]("Creates a json file containing webjar toc")
    val webjarFile = settingKey[String]("The source file name")
    val webjarPackage = settingKey[String]("The package name")
    val webjarPrefix = settingKey[String]("The path name into the jar file")
    val webjarWebPackages = settingKey[Seq[Task[WebPackage]]]("More resources to add")
    val webjarWebPackageResources = taskKey[Seq[File]]("Copy web package files to resource location")

    case class WebPackage(groupId: String, artifactId: String, version: String, files: Seq[(File, String)]) {
      lazy val hash = Hash.toHex(Hash(files.map(f => Hash(f._1)).mkString + s"$groupId:$artifactId:$version"))
      lazy val moduleID: ModuleID = groupId % artifactId % version
      private[WebjarPlugin] lazy val toWebjar = Webjar(moduleID, hash, file(""))
      private[WebjarPlugin] lazy val entries: Map[String, FileInfo] = files.
        map({ case (f, name) =>
          name -> FileInfo(Webjar.detect(f.getName), f.length)
        }).
        toMap
    }
  }

  import autoImport._

  val webjarSettings = Seq(
    webjarFile in webjarSource := "Webjars.scala",
    webjarPackage in webjarSource := "webjars",
    webjarWebPackages := Seq.empty,
    webjarSource := {
      val logger = streams.value.log
      val entry = packageToFile((webjarPackage in webjarSource).value)
      val target = (sourceManaged in Compile).value/entry/(webjarFile in webjarSource).value
      val webjars: Seq[ModuleID] = (libraryDependencies in Compile).value.filter(_.organization startsWith "org.webjars")
      val files: Seq[Webjar] = Attributed.data((dependencyClasspath in Compile).value).collect(findWebjarFile(webjars)) ++
        internalResources.value.map(_.toWebjar)
      val code = s"""package ${(webjarPackage in webjarSource).value}
      |object ${(webjarFile in webjarSource).value.dropRight(6)} {
      |  case class ModuleId(groupId: String, artifactId: String, version: String, hash: String) {
      |    val resourcePrefix = s"/META-INF/resources/webjars/$${artifactId}/$${version}"
      |  }
      |  case class FileInfo(contentType: String, length: Long)
      |  type Hash = String
      |  type Path = String
      |  type Toc = Map[Hash, Map[Path, FileInfo]]
      |  val lastModified = java.time.Instant.parse("${Instant.now.toString}")
      |  val modules = ${files.map({ wj => "ModuleId(\""+wj.module.organization+"\", \""+wj.module.name+"\", \""+ wj.module.revision +"\", \""+wj.hash+"\")"})}
      |}""".stripMargin
      if (!target.exists || Hash.toHex(Hash(target)) != Hash.toHex(Hash(code))) {
        logger.info(s"Generating ${(webjarFile in webjarSource).value}")
        IO.createDirectories(Seq(target.getParentFile))
        IO.write(target, code)
      }
      Seq(target)
    },
    webjarContents := {
      streams.value.log.info("Generating webjar toc file")
      val entry = packageToFile((webjarPackage in webjarSource).value)
      val target = (resourceManaged in Compile).value/entry/"toc.json"
      val webjars: Seq[ModuleID] = (libraryDependencies in Compile).value.filter(_.organization startsWith "org.webjars")
      val files: Seq[Webjar] = Attributed.data((dependencyClasspath in Compile).value).collect(findWebjarFile(webjars))
      val libMap = files.map(wj => wj.hash -> wj.listEntries).toMap
      val intMap = internalResources.value.map(r => r.hash -> r.entries)
      IO.createDirectories(Seq(target.getParentFile))
      IO.write(target, (libMap ++ intMap).asJson.spaces2)
      Seq(target)
    },
    webjarWebPackageResources := {
      val base = resourceManaged.value/"META-INF"/"resources"/"webjars"
      val pkgs: Seq[WebPackage] = internalResources.value
      pkgs.flatMap { wp =>
        wp.files.map { case (f, name) =>
          val target = base/wp.artifactId/wp.version/name
          IO.copy(Seq(f -> target))
          target
        }
      }
    }
  )

  override def projectSettings =
    inConfig(Compile)(webjarSettings)


  private def packageToFile(pkg: String) =
    pkg.replace(".", java.io.File.separator)

  lazy val internalResources = Def.taskDyn {
    evalWebPackage(webjarWebPackages.value)
  }

  def evalWebPackage(ts: Seq[Task[WebPackage]]): Def.Initialize[Task[List[WebPackage]]] = Def.taskDyn {
    ts.headOption match {
      case None => Def.task[List[WebPackage]](Nil)
      case Some(r) => Def.taskDyn {
        val head = r.value
        Def.task[List[WebPackage]](head :: evalWebPackage(ts.drop(1)).value)
      }
    }
  }

  case class FileInfo(contentType: String, length: Long)

  case class Webjar(module: ModuleID, hash: String, file: File) {
    val resourcePrefix = s"/META-INF/resources/webjars/${module.name}/${module.revision}"

    def listEntries: Map[String, FileInfo] = {
      if (!file.exists) sys.error(file.toString)
      def loop(in: ZipInputStream, entries: List[(String, FileInfo)]): List[(String, FileInfo)] =
        Option(in.getNextEntry) match {
          case Some(e) if e.getName.startsWith(resourcePrefix.substring(1)) && !e.getName.endsWith("/") =>
            loop(in, (e.getName.substring(resourcePrefix.length), FileInfo(Webjar.detect(e.getName), e.getSize)) :: entries)
          case Some(_) =>
            loop(in, entries)
          case _ =>
            entries
        }

      closing(new ZipInputStream(new FileInputStream(file))) { zin =>
        loop(zin, Nil).toMap
      }
    }
  }

  object Webjar {
    private val tika = new Tika()
    def detect(f: File): String = tika.detect(f)
    def detect(name: String): String = tika.detect(name)
  }

  def findModuleID(webjars: Seq[ModuleID], file: File): Option[ModuleID] = {
    val s = file.toPath.normalize.toAbsolutePath.asScala.mkString(".")
    webjars.find(m => s.contains(m.organization+ "." + m.name))
  }

  def isWebjarFile(webjars: Seq[ModuleID], file: File): Boolean =
    findModuleID(webjars, file).isDefined

  def findWebjarFile(webjars: Seq[ModuleID]): PartialFunction[File, Webjar] = {
    case f if isWebjarFile(webjars, f) =>
      Webjar(findModuleID(webjars, f).get, Hash.toHex(Hash(f)), f)
  }

  private def closing[A <: AutoCloseable, B](in: A)(body: A => B): B = {
    try {
      body(in)
    } finally {
      in.close()
    }
  }
}
