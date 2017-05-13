package sharry.server.email

trait Header {
  def name: String
}

object Header {
  case class GenericHeader(name: String, value: String) extends Header

  case class To(mail: Address) extends Header {
    val name = To.name
  }
  object To { val name = "To" }

  case class Subject(line: String) extends Header {
    val name = Subject.name
  }
  object Subject { val name = "Subject" }
}
