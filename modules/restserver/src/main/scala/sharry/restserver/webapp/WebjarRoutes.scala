package sharry.restserver.webapp

import cats.effect.*

import org.http4s.HttpRoutes
import org.http4s.server.staticcontent.*

object WebjarRoutes {

  def appRoutes[F[_]: Async]: HttpRoutes[F] =
    webjarServiceBuilder[F]
      .withCacheStrategy(NoopCacheStrategy[F])
      .withWebjarAssetFilter(assetFilter)
      .toRoutes

  def assetFilter(asset: WebjarServiceBuilder.WebjarAsset): Boolean =
    List(
      ".js",
      ".css",
      ".html",
      ".jpg",
      ".png",
      ".eot",
      ".json",
      ".woff",
      ".woff2",
      ".svg",
      ".map",
      ".otf",
      ".ttf",
      ".yml"
    ).exists(e => asset.asset.endsWith(e))

}
