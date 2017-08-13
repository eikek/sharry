package sharry

import com.vladsch.flexmark.util.sequence._
import com.vladsch.flexmark.ast._
import scala.reflect._

package object mdutil {

  private[mdutil] def chars(s: String): BasedSequence =
    CharSubSequence.of(s)


  private[mdutil] def visitHandler[T <: Node : ClassTag](f: T => Unit): VisitHandler[T] = {
    val c = classTag[T].runtimeClass.asInstanceOf[Class[T]]
    new VisitHandler[T](c, new Visitor[T] {
      override def visit(node: T): Unit = f(node)
    })
  }
}
