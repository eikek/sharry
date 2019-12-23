package sharry.restserver.routes

import sharry.common.Ident
import sharry.store.AddResult
import sharry.restapi.model.BasicResult
import sharry.restapi.model.IdResult
import sharry.backend.share.UploadResult

object Conv {

  def basicResult(ar: AddResult, successMsg: String): BasicResult =
    ar match {
      case AddResult.Success =>
        BasicResult(true, successMsg)
      case AddResult.EntityExists(msg) =>
        BasicResult(false, msg)
      case AddResult.Failure(ex) =>
        BasicResult(false, ex.getMessage)
    }

  def idResult(successMsg: String)(ar: Either[Throwable, Ident]): IdResult =
    ar match {
      case Right(id) => IdResult(true, successMsg, id)
      case Left(ex)  => IdResult(false, s"${ex.getClass}: ${ex.getMessage}", Ident.empty)
    }

  def uploadResult(successMsg: String)(ur: UploadResult[Ident]): IdResult =
    ur match {
      case UploadResult.Success(id) =>
        IdResult(true, successMsg, id)
      case UploadResult.ValidityExceeded(max) =>
        IdResult(false, s"Maximum validity ($max) exceeded", Ident.empty)
      case UploadResult.SizeExceeded(max) =>
        IdResult(false, s"Maximum size ($max) exceeded", Ident.empty)
    }

  def uploadBasicResult[A](successMsg: String)(ur: UploadResult[A]): BasicResult =
    ur match {
      case UploadResult.Success(_) =>
        BasicResult(true, successMsg)
      case UploadResult.ValidityExceeded(max) =>
        BasicResult(false, s"Maximum validity ($max) exceeded")
      case UploadResult.SizeExceeded(max) =>
        BasicResult(false, s"Maximum size ($max) exceeded")
    }
}
