package sharry.server.routes

import fs2.Stream
import cats.effect.IO
import spinoco.fs2.http.routing._

import sharry.common.data._
import sharry.server.paths
import sharry.server.routes.syntax._

object settings {

  def endpoint(rcfg: RemoteConfig): Route[IO] =
    remoteConfig(rcfg)


  def remoteConfig(rcfg: RemoteConfig): Route[IO] =
    Get >> paths.settings.matcher map { _ =>
      Stream.eval(IO { Ok.body(rcfg) })
    }

}
