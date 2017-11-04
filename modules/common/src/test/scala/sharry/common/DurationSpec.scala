package sharry.common

import org.scalatest._
import cats.data.Validated
import cats.data.Validated.{invalid, valid}

import sharry.common.duration._
import sharry.common.duration.{DurationParser => parser}

class DurationSpec extends FlatSpec with Matchers {

  "Duration" should "create values" in {
    1.hours.minutes should be (60)
    2.hours.minutes should be (120)
    1.hours.days should be (0)
    1.hours.seconds should be (3600)
    1.days.hours should be (24)
    2.days.hours should be (48)
    10.days.hours should be (240)
    100.days.hours should be (2400)
    200.days.hours should be (4800)
    500.days.minutes should be (720000)

    1.5.days.hours should be (36)
    200.5.days.hours should be (4812)
    0.days should be (0.minutes)
    0.seconds should be (0.minutes)
    0.hours should be (Duration.zero)

    (-2).minutes.seconds should be (-120)
  }

  it should "calculate" in {
    96.minutes * 2 should be (192.minutes)
    10.minutes + 5.minutes should be (15.minutes)
    5.minutes - 10.minutes should be (-5.minutes)
    -4.hours.isNegative should be (true)
  }

  it should "parse hh:mm:ss format" in {
    parser.hhmmss.parse("1:36:00") should be (valid(96.minutes))
    parser.hhmmss.parse("1:10") should be (valid(1.minutes + 10.seconds))
    parser.hhmmss.parse("1:10:10") should be (valid(1.hours + 10.minutes + 10.seconds))
    parser.hhmmss.parse("1:1:1") should be (valid(1.hours + 1.minutes + 1.seconds))
    parser.hhmmss.parse("100:1") should be (valid(100.minutes + 1.seconds))
    parser.hhmmss.parse("2:1") should be (valid(2.minutes + 1.seconds))
    parser.hhmmss.parse("-2:1") should be (valid((2.minutes + 1.seconds) * -1))

    parser.hhmmss.parse("1:100:1") should be (invalid("Cannot read '1:100:1' near position 5: Minutes must be between 0 and 59"))
    parser.hhmmss.parse("1:1x:2") should be (invalid("Cannot read '1:1x:2' near position 3: Expected end of string, but got: x:2"))
    parser.hhmmss.parse("1:1x") should be (invalid("Cannot read '1:1x' near position 3: Expected end of string, but got: x"))
    parser.hhmmss.parse(":10") should be (invalid("Cannot read ':10' near position 0: Expected matching ^\\d+, but got: :10"))
  }

  it should "parse the verbose format" in {
    parser.wordy.parse("12 days 20hours 14min 10secs") should be (valid(12.days + 20.hours + 14.minutes + 10.seconds))
    parser.wordy.parse("20hours 14min 12 days 10secs") should be (valid(12.days + 20.hours + 14.minutes + 10.seconds))
    parser.wordy.parse("1 day 20hours") should be (valid(1.days + 20.hours))
    parser.wordy.parse(454841.seconds.format(DurationFormat.wordy)) should be (valid(454841.seconds))

    parser.wordy.parse("1x days") should be (invalid("Cannot read '1x days' near position 1: Expected one of: d, h, m, s, but got: x days"))
    parser.wordy.parse("3days HAHAHA 6day 1d") should be (Validated.invalid("Cannot read '3days HAHAHA 6day 1d' near position 6: Expected end of string, but got: HAHAHA 6day 1d"))
    parser.wordy.parse("3days 6day 1d") should be (Validated.valid(10.days))
  }

  it should "not backtrack parsing on some inputs" in {
    Duration.parse("1:mx") should be (invalid("Cannot read '1:mx' near position 2: Expected matching ^\\d+, but got: mx"))
    Duration.parse("1 day X") should be (invalid("Cannot read '1 day X' near position 6: Expected end of string, but got: X"))
  }

  it should "format a duration to hh:mm[:ss]" in {
    96.minutes.format(DurationFormat.hhmmss) should be ("1:36:00")
    150.millis.format(DurationFormat.hhmmss) should be ("150ms")
    1.seconds.format(DurationFormat.hhmmss) should be ("00:01")
    63.seconds.format(DurationFormat.hhmmss) should be ("01:03")
    150.millis.formatExact should be ("PT0.15S")
    (42.days + 10.minutes).format(DurationFormat.hhmmss) should be ("1008:10:00")
  }

  it should "format a duration to wordy format" in {
    96.minutes.format(DurationFormat.wordy) should be ("1 hour 36 min")
    DurationFormat.wordy.format(96.minutes) should be ("1 hour 36 min")

    454841.seconds.format(DurationFormat.wordy) should be ("5 days 6 hours 20 min 41 secs")
    433241.seconds.format(DurationFormat.wordy) should be ("5 days 20 min 41 secs")
    12.seconds.format(DurationFormat.wordy) should be ("12 secs")

    (42.days + 10.minutes).format(DurationFormat.wordy) should be ("42 days 10 min")
    120.millis.format(DurationFormat.wordy) should be ("120ms")
  }
}
