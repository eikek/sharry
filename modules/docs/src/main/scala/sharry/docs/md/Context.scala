package sharry.docs.md

import yamusca.context.{Context => YContext, Value}

case class Context(
  version: String
    , defaultConfig: String) extends YContext {

  def find(key: String): (YContext, Option[Value]) = key match {
    case "version" => (this, Some(Value.of(version)))
    case "default-configuration" => (this, Some(Value.of(defaultConfig)))
    case _ => (this, None)
  }
}
