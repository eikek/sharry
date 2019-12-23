package sharry.backend

package object auth {

  import cats.data.Kleisli

  type LoginModule[F[_]] = Kleisli[F, UserPassData, Option[LoginResult]]

}
