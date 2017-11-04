package sharry.server.routes

import fs2.{Stream, Task}
import spinoco.fs2.http.routing._

import sharry.common.data._
import sharry.server.paths
import sharry.server.routes.syntax._

object settings {

  def endpoint(rcfg: RemoteConfig): Route[Task] =
    remoteConfig(rcfg)


  def remoteConfig(rcfg: RemoteConfig): Route[Task] =
    Get >> paths.settings.matcher map { _ =>
      Stream.eval(Task.delay { Ok.body(rcfg) })
    }

}
