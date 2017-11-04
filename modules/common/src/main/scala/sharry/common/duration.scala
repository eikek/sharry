package sharry.common

import java.time.{Duration => JDur}
import java.time.temporal.Temporal
import scala.concurrent.duration.{Duration => SDur, FiniteDuration, MILLISECONDS}
import cats.data.Validated
import cats.{Order, Monoid}
import cats.implicits._

/** Finite duration bit more convenient to use with this code base. It
  * consolidates usages of {{{java.time.Duration}}} and the scala
  * variant in {{{scala.concurrent}}}.
  *
  * Duration values can be parsed using different parsers and
  * formatted using different formatters to human readable output or
  * an exact representation.
  *
  * The default parser first tries the hh:mm[:ss] format, then a
  * verbose one (like '1 days 15 minutes') and then using
  * javas {{{Duration}}} class.
  */
object duration {

  case class Duration(millis: Long) {

    def +(other: Duration): Duration =
      Duration(millis + other.millis)

    def *(factor: Double): Duration =
      Duration((millis * factor).toLong)

    def *(factor: Int): Duration =
      Duration((millis * factor).toLong)

    def *(factor: Long): Duration =
      Duration((millis * factor).toLong)

    def -(other: Duration): Duration =
      Duration(millis - other.millis)

    def isNegative: Boolean = millis < 0

    def isPositive: Boolean = millis > 0

    def isZero: Boolean = millis == 0

    def >=(other: Duration): Boolean = millis >= other.millis

    def <=(other: Duration): Boolean = millis <= other.millis

    def asScala: FiniteDuration = FiniteDuration(millis, MILLISECONDS)

    def asJava: JDur = JDur.ofMillis(millis)

    def seconds: Long = millis / 1000

    def minutes: Long = seconds / 60

    def hours: Long = minutes / 60

    def days: Long = hours / 24

    def parts: List[Long] = {
      val d = days
      val h = (this - d.days).hours
      val m = (this - d.days - h.hours).minutes
      val s = (this - d.days - h.hours - m.minutes).seconds
      val ms = (this - d.days - h.hours - m.minutes - s.seconds).millis
      List(d,h,m,s,ms)
    }

    def format(implicit fmt: DurationFormat): String =
      fmt.format(this)

    def formatExact = format(DurationFormat.java)

    override def toString(): String = s"Duration($formatExact)"
  }

  object Duration {

    val zero: Duration = Duration(0L)

    def between(ta: Temporal, tb: Temporal): Duration =
      fromJava(JDur.between(ta,tb))

    def parse(str: String)(implicit parser: DurationParser): Validated[String, Duration] =
      parser.parse(str.trim)

    def fromJava(dur: JDur): Duration = Duration(dur.toMillis)

    def fromScala(dur: SDur): Duration = Duration(dur.toMillis)

    def unsafeParse(str: String): Duration =
      parse(str) match {
        case Validated.Valid(d) => d
        case Validated.Invalid(msg) => throw new IllegalArgumentException(msg)
      }

    implicit val monoid: Monoid[Duration] = new Monoid[Duration] {
      val empty: Duration = Duration.zero
      def combine(a: Duration, b: Duration) =
        Duration(Monoid[Long].combine(a.millis, b.millis))
    }

    implicit val order: Order[Duration] =
      Order[Long].on(_.millis)
  }

  trait DurationFormat {
    def format(d: Duration): String
  }

  object DurationFormat {
    implicit val defaultFormat = wordy

    case object hhmmss extends DurationFormat {
      def format(duration: Duration) = {
        val List(d,hh,m,s,ms) = duration.parts
        val h = hh + (d * 24)
        if ((h+m+s) == 0) s"${duration.millis}ms"
        else if (h > 0) "%d:%02d:%02d".format(h,m,s)
        else "%02d:%02d".format(m,s)
      }
    }

    case object wordy extends DurationFormat {
      def format(duration: Duration) = {
        val List(d,h,m,s,ms) = duration.parts
        def mk(n: Long, single: String, multiple: String): String =
          n match {
            case 0 => ""
            case 1 => s"$n $single "
            case _ => s"$n $multiple "
          }

        val days = mk(d, "day", "days")
        val hours = mk(h, "hour", "hours")
        val mins = mk(m, "min", "min")
        val secs = mk(s, "sec", "secs")
        if ((d+h+m+s) == 0) s"${duration.millis}ms"
        else (days + hours + mins + secs).trim
      }
    }

    case object java extends DurationFormat {
      def format(duration: Duration) =
        duration.asJava.toString
    }
  }

  trait DurationParser { self =>
    def parser: DurationParser.internal.P[Duration]

    def parse(s: String): Validated[String, Duration] = parser.parse(s.trim)

    def or(next: DurationParser): DurationParser = new DurationParser {
      def parser = self.parser.or(next.parser)
    }
  }
  object DurationParser {
    import internal._

    implicit val defaultParser: DurationParser = hhmmss.or(wordy).or(java)

    object hhmmss extends DurationParser {
      val sign:P[Int] = P.literal("-").opt.map(_.map(_ => -1).getOrElse(1))
      val hhhh = (P.int ~ P.literal(":")).cut.map(_._1)
      val mm = P.int.
        mapV(n => Validated.valid(n).ensure("Minutes must be between 0 and 59")(n => n >= 0 && n <= 59))

      val ss = (P.literal(":") ~ P.int.
        mapV(n => Validated.valid(n).ensure("Seconds must be between 0 and 59")(n => n >= 0 && n <= 59))).
        map(_._2).
        opt

      val parser = (sign ~ hhhh ~ mm ~ ss ~ P.done).map {
        case ((((sign, h), m),s),_) => s match {
          case Some(n) =>
            (h.hours + m.minutes + n.seconds) * sign
          case None =>
            (h.minutes + m.seconds) * sign
        }
      }
    }

    object wordy extends DurationParser {
      val toDay: P[Double => Duration] = P.literalsOr("days", "day", "d").map(_ => (n => n.days))
      val toHour: P[Double => Duration] = P.literalsOr("hours", "hour", "h").map(_ => (n => n.hours))
      val toMin: P[Double => Duration] = P.literalsOr("minutes", "minute", "min", "m").map(_ => (n => n.minutes))
      val toSec: P[Double => Duration] = P.literalsOr("seconds", "secs", "s").map(_ => (n => n.seconds))

      val p0 = (P.number ~ P.ws ~ (P.oneOf("d","h","m","s").peek.cut) ~ (toDay or toHour or toMin or toSec)).map {
        case (((n, _), _), f) => f(n)
      }

      val parser = (P.repeat1(p0 ~ P.ws).map(_.map(_._1)) ~ P.done).map {
        case (ds, _) => Monoid[Duration].combineAll(ds)
      }
    }

    object millis extends DurationParser {
      val parser = P.int.map(_.millis)
    }

    object java extends DurationParser {
      val parser = P { in =>
        Validated.catchNonFatal(Duration.fromJava(JDur.parse(in.current))).
          map(d => (in.moveToEnd, d)).
          leftMap(ex => (in, ex.getMessage))
      }
    }

    object internal {
      case class Input(in: String, pos: Int = 0, cut: Int = 0) {
        val current = in.substring(pos)
        def next(p: Int) = copy(pos = pos + p)
        def consumeWs: Input = current.takeWhile(Set(' ', '\t').contains).size match {
          case 0 => this
          case n => copy(pos = pos + n)
        }
        def moveToEnd: Input = copy(pos = in.length)
      }

      trait P[A] extends (Input => Validated[(Input, String), (Input, A)]) { self =>

        def map[B](f: A => B): P[B] = P { in =>
          self(in).map { case (nin, a) =>
            (nin, f(a))
          }
        }
        def mapV[B](f: A => Validated[String, B]): P[B] = P { in =>
          self(in).andThen { case (nin, a) =>
            f(a).map(b => (nin, b)).leftMap(s => (nin, s))
          }
        }

        def ~[B](next: P[B]): P[(A,B)] = P { in =>
          self(in).andThen { case (nin,a) =>
            next(nin).map { case (nin2, b) =>
              (nin2, (a,b))
            }
          }
        }

        def opt: P[Option[A]] = P { in =>
          self(in).
            map(t => (t._1, Some(t._2))).
            fold(e => Validated.valid((e._1, None)), Validated.valid)
        }

        def cut: P[A] = P { in =>
          self(in).map { case (nin, a) =>
            (nin.copy(cut = nin.pos), a)
          }
        }

        def or[B >: A](p: P[B]): P[B] = { in =>
          self(in) match {
            case v@Validated.Valid(_) => v
            case e@Validated.Invalid((nin, err)) =>
              if (nin.cut <= in.pos) p(in)
              else e
          }
        }

        def peek: P[A] = P { in =>
          self(in).map({ case (nin, a) => (in, a) })
        }

        def parse(in: String): Validated[String, A] =
          self(Input(in)).
            map(_._2).
            leftMap({ case (rest, err) =>
              s"Cannot read '$in' near position ${rest.pos}: $err"
            })
      }
      object P {
        def apply[A](f: Input => Validated[(Input, String), (Input,A)]): P[A] = new P[A] {
          def apply(in: Input) = f(in)
        }

        def regex(reg: String): P[String] = P { in =>
          reg.r.findFirstMatchIn(in.current).
            map(m => Validated.valid((in.next(m.end), m.group(0)))).
            getOrElse(Validated.invalid((in, s"Expected matching $reg, but got: ${in.current}")))
        }
        def literal(lit: String): P[String] = P { in =>
          if (in.current.startsWith(lit)) Validated.valid((in.next(lit.length), lit))
          else Validated.invalid((in, s"Expected '$lit', but got: ${in.current}"))
        }

        def literalsOr(lit0: String, litN: String*): P[String] =
          (lit0 +: litN).map(literal).reduce(_ or _)

        def oneOf(s0: String, s1: String, sN: String*): P[String] = {
          val words = (s0 +: s1 +: sN).toSet
          P { in =>
            words.find(in.current.startsWith).
              map(w => Validated.valid((in.next(w.length), w))).
              getOrElse(Validated.invalid((in, s"Expected one of: ${words.toList.sorted.mkString(", ")}, but got: ${in.current}")))
          }
        }

        def number: P[Double] =
          regex("^\\d+(\\.\\d+)?").mapV(s => Validated.catchNonFatal(s.toDouble).leftMap(_.getMessage))

        def int: P[Int] =
          regex("^\\d+").map(_.toInt)

        def ws: P[Unit] = P { in =>
          Validated.valid((in.consumeWs, ()))
        }

        def done: P[Unit] = P { in =>
          if (in.current.isEmpty) Validated.valid((in, ()))
          else Validated.invalid((in, s"Expected end of string, but got: ${in.current}"))
        }

        def repeat1[A](p: P[A]): P[Seq[A]] = P { pin =>
          @annotation.tailrec
          def go(in: Input, result: Vector[A]): Validated[(Input, String), (Input, Vector[A])] = {
            if (in.current.isEmpty)
              if (result.isEmpty) Validated.invalid((in, "Unexpected end of input"))
              else Validated.valid(in -> result)
              else p(in) match {
                case Validated.Valid((next, a)) =>
                  go(next, result :+ a)
                case e@Validated.Invalid((next, err)) =>
                  if (result.isEmpty) e
                  else Validated.valid(next -> result)
              }
          }
          go(pin, Vector.empty)
        }
      }
    }
  }

  implicit class LongToDuration(val n: Long) extends AnyVal {
    def millis = Duration(n)
    def seconds = (n * 1000).millis
    def minutes = (n * 60).seconds
    def hours = (n * 60).minutes
    def days = (n * 24).hours
  }
  implicit class IntToDuration(val n: Int) extends AnyVal {
    def millis = Duration(n.toLong)
    def seconds = (n.toLong * 1000).millis
    def minutes = (n.toLong * 60).seconds
    def hours = (n.toLong * 60).minutes
    def days = (n.toLong * 24).hours
  }
  implicit class DoubleToDuration(val n: Double) extends AnyVal {
    def millis = Duration(n.toLong)
    def seconds = (n * 1000).millis
    def minutes = (n * 60).seconds
    def hours = (n * 60).minutes
    def days = (n * 24).hours
  }
}
