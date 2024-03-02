package sharry.restserver.webapp

import java.net.URL
import java.util.concurrent.atomic.AtomicReference

import cats.effect._
import cats.implicits._
import fs2._
import fs2.io.file.{Files, Path}

import sharry.logging.Logger
import sharry.restapi.model.AppConfig
import sharry.restserver.BuildInfo
import sharry.restserver.config.Config
import sharry.restserver.routes.InfoRoutes
import sharry.restserver.webapp.YamuscaConverter._

import _root_.io.circe.syntax._
import org.http4s.HttpRoutes
import org.http4s._
import org.http4s.dsl.Http4sDsl
import org.http4s.headers._
import yamusca.derive._
import yamusca.implicits._
import yamusca.imports._

object TemplateRoutes {

  val `text/html` = new MediaType("text", "html")
  val `application/javascript` = new MediaType("application", "javascript")

  trait InnerRoutes[F[_]] {
    def doc: HttpRoutes[F]
    def app: HttpRoutes[F]
    def serviceWorker: HttpRoutes[F]
  }

  def apply[F[_]: Async: Files](cfg: Config): InnerRoutes[F] = {
    implicit val logger = sharry.logging.getLogger[F]
    val indexTemplate = memo(
      loadResource("/index.html").flatMap(loadTemplate(_))
    )
    val docTemplate = memo(loadResource("/doc.html").flatMap(loadTemplate(_)))
    val swTemplate = memo(loadResource("/sw.js").flatMap(loadTemplate(_)))
    val indexData = memo(IndexData(cfg))

    val dsl = new Http4sDsl[F] {}
    import dsl._
    new InnerRoutes[F] {
      def doc =
        HttpRoutes.of[F] { case GET -> Root =>
          for {
            templ <- docTemplate
            resp <- Ok(
              DocData().render(templ),
              `Content-Type`(`text/html`, Charset.`UTF-8`)
            )
          } yield resp
        }
      def app =
        HttpRoutes.of[F] { case GET -> _ =>
          for {
            templ <- indexTemplate
            data <- indexData
            resp <- Ok(data.render(templ), `Content-Type`(`text/html`, Charset.`UTF-8`))
          } yield resp
        }
      def serviceWorker =
        HttpRoutes.of[F] { case GET -> _ =>
          for {
            templ <- swTemplate
            data <- indexData
            resp <- Ok(
              data.render(templ),
              `Content-Type`(`application/javascript`, Charset.`UTF-8`)
            )
          } yield resp
        }
    }
  }

  def loadResource[F[_]: Sync](name: String): F[URL] =
    Option(getClass.getResource(name)) match {
      case None =>
        Sync[F].raiseError(new Exception("Unknown resource: " + name))
      case Some(r) =>
        r.pure[F]
    }

  def loadUrl[F[_]: Sync](url: URL): F[String] =
    Stream
      .bracket(Sync[F].blocking(url.openStream))(in => Sync[F].blocking(in.close))
      .flatMap(in => io.readInputStream(in.pure[F], 64 * 1024, closeAfterUse = false))
      .through(text.utf8.decode)
      .compile
      .fold("")(_ + _)

  def parseTemplate[F[_]: Sync](str: String): F[Template] =
    Sync[F].delay {
      mustache.parse(str) match {
        case Right(t)       => t
        case Left((_, err)) => sys.error(err)
      }
    }

  def loadTemplate[F[_]: Sync: Logger](url: URL): F[Template] =
    loadUrl[F](url)
      .flatMap(s => parseTemplate(s))
      .flatMap { t =>
        Logger[F].info(s"Compiled template $url").as(t)
      }

  case class DocData(swaggerRoot: String, openapiSpec: String)
  object DocData {

    def apply(): DocData =
      DocData(
        "/app/assets" + Webjars.swaggerui,
        s"/app/assets/${BuildInfo.name}/${BuildInfo.version}/sharry-openapi.yml"
      )

    implicit def yamuscaValueConverter: ValueConverter[DocData] =
      deriveValueConverter[DocData]
  }

  case class IndexData(
      flags: AppConfig,
      cssUrls: Seq[String],
      jsUrls: Seq[String],
      appExtraJs: String,
      flagsJson: String,
      customHead: String
  )

  object IndexData {
    val favIconBase = s"/app/assets/sharry-webapp/${BuildInfo.version}/favicon"

    val defaultHead =
      s"""
         |<link rel="apple-touch-icon" sizes="180x180" href="$favIconBase/apple-touch-icon.png">
         |<link rel="icon" type="image/png" sizes="32x32" href="$favIconBase/favicon-32x32.png">
         |<link rel="icon" type="image/png" sizes="16x16" href="$favIconBase/favicon-16x16.png">
         |<link rel="manifest" href="$favIconBase/manifest.json">
         |<link rel="mask-icon" href="$favIconBase/safari-pinned-tab.svg" color="#5bbad5">
         |<meta name="theme-color" content="#ffffff">
         |""".stripMargin

    def apply[F[_]: Sync: Files: Logger](cfg: Config): F[IndexData] =
      loadCustomHead(cfg).map { headSection =>
        IndexData(
          InfoRoutes.appConfig(cfg),
          Seq(
            s"/app/assets/sharry-webapp/${BuildInfo.version}/css/styles.css"
          ),
          Seq(
            "/app/assets" + Webjars.tusjsclient + "/dist/tus.min.js",
            "/app/assets" + Webjars.clipboardjs + "/clipboard.min.js",
            s"/app/assets/sharry-webapp/${BuildInfo.version}/sharry-app.js"
          ),
          s"/app/assets/sharry-webapp/${BuildInfo.version}/sharry.js",
          InfoRoutes.appConfig(cfg).asJson.spaces2,
          headSection
        )
      }

    private def loadCustomHead[F[_]: Sync: Files: Logger](cfg: Config): F[String] = {
      val nonEmptyHead = Stream.emit(cfg.webapp.customHead).filter(_.nonEmpty).covary[F]

      val readFile =
        nonEmptyHead
          .map(Path(_))
          .evalFilter(Files[F].exists)
          .evalTap(p => Logger[F].info(s"Including head section from file: $p"))
          .evalMap(p => Files[F].readUtf8(p).compile.string)

      val plainValue = nonEmptyHead.evalTap { _ =>
        Logger[F]
          .info("Use custom head section as plain string into main template")
      }

      val default = Stream.eval(
        Logger[F]
          .info(s"Use default head section for main template")
          .as(defaultHead)
      )

      (readFile ++ plainValue ++ default).head.compile.lastOrError
    }

    implicit def yamuscaValueConverter: ValueConverter[IndexData] =
      deriveValueConverter[IndexData]
  }

  private def memo[F[_]: Sync, A](fa: => F[A]): F[A] = {
    val ref = new AtomicReference[A]()
    Sync[F].defer {
      Option(ref.get) match {
        case Some(a) => a.pure[F]
        case None =>
          fa.map { a =>
            ref.set(a)
            a
          }
      }
    }
  }
}
