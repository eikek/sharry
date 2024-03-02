package sharry.restserver.routes

import cats.data.NonEmptyList
import cats.implicits._
import cats.{ApplicativeError, MonadError}

import sharry.backend.share.UploadResult
import sharry.common.Ident
import sharry.restapi.model.BasicResult
import sharry.restapi.model.IdResult
import sharry.store.AddResult

import io.circe.DecodingFailure

object Conv {

  def readId[F[_]](
      id: String
  )(implicit F: ApplicativeError[F, Throwable]): F[Ident] =
    Ident
      .fromString(id)
      .fold(
        err => F.raiseError(DecodingFailure(err, Nil)),
        F.pure
      )

  def readIdsNonEmpty[F[_]](ids: List[String])(implicit
      F: MonadError[F, Throwable]
  ): F[NonEmptyList[Ident]] =
    ids.traverse(readId[F]).map(NonEmptyList.fromList).flatMap {
      case Some(nel) => nel.pure[F]
      case None =>
        F.raiseError(
          DecodingFailure("Empty list found, at least one element required", Nil)
        )
    }

  def readIds[F[_]](ids: List[String])(implicit
      F: MonadError[F, Throwable]
  ): F[List[Ident]] =
    ids.traverse(readId[F])

  def basicResult(ar: AddResult, successMsg: String): BasicResult =
    ar match {
      case AddResult.Success =>
        BasicResult(success = true, successMsg)
      case AddResult.EntityExists(msg) =>
        BasicResult(success = false, msg)
      case AddResult.Failure(ex) =>
        BasicResult(success = false, ex.getMessage)
    }

  def idResult(successMsg: String)(ar: Either[Throwable, Ident]): IdResult =
    ar match {
      case Right(id) => IdResult(success = true, successMsg, id)
      case Left(ex) =>
        IdResult(success = false, s"${ex.getClass}: ${ex.getMessage}", Ident.empty)
    }

  def uploadResult(successMsg: String)(ur: UploadResult[Ident]): IdResult =
    ur match {
      case UploadResult.Success(id) =>
        IdResult(success = true, successMsg, id)
      case UploadResult.ValidityExceeded(max) =>
        IdResult(success = false, s"Maximum validity ($max) exceeded", Ident.empty)
      case UploadResult.SizeExceeded(max) =>
        IdResult(success = false, s"Maximum size ($max) exceeded", Ident.empty)
      case UploadResult.PermanentError(msg) =>
        IdResult(success = false, msg, Ident.empty)
    }

  def uploadBasicResult[A](successMsg: String)(ur: UploadResult[A]): BasicResult =
    ur match {
      case UploadResult.Success(_) =>
        BasicResult(success = true, successMsg)
      case UploadResult.ValidityExceeded(max) =>
        BasicResult(success = false, s"Maximum validity ($max) exceeded")
      case UploadResult.SizeExceeded(max) =>
        BasicResult(success = false, s"Maximum size ($max) exceeded")
      case UploadResult.PermanentError(msg) =>
        BasicResult(success = false, msg)
    }
}
