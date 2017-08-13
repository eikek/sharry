package sharry.cli

class LoggingProperty extends ch.qos.logback.core.PropertyDefinerBase {

  @scala.beans.BeanProperty
  var name: String = ""

  def getPropertyValue(): String = {
    val key = s"sharry.$name"
    val value = Option(getContext.getProperty(key))
    value.filter(_.nonEmpty).getOrElse("warn")
  }
}
