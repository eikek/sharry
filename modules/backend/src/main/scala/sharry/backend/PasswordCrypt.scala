package sharry.backend

import sharry.common.Password
import org.mindrot.jbcrypt.BCrypt

object PasswordCrypt {

  def crypt(pass: Password): Password =
    if (pass.isEmpty) pass
    else Password(BCrypt.hashpw(pass.pass, BCrypt.gensalt()))

  def check(plain: Password, hashed: Password): Boolean =
    hashed.nonEmpty && plain.nonEmpty && BCrypt.checkpw(plain.pass, hashed.pass)

}
