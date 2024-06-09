package sharry.restserver.config

import com.typesafe.config.{Config, ConfigValue as TCValue}
import ciris._
import com.typesafe.config.ConfigException
import com.typesafe.config.ConfigFactory

private[config] object Hocon:
  final class HoconAt(config: Config, path: String):
    def apply(name: String): ConfigValue[Effect, TCValue] =
      val key = s"$path.$name"
      val ckey = ConfigKey(key)
      try
        val value = config.getValue(key)
        ConfigValue.loaded(ckey, value)
      catch
        case _: ConfigException.Missing => ConfigValue.missing(ckey)
        case ex => ConfigValue.failed(ConfigError(ex.getMessage))

  def at(config: Config)(path: String): HoconAt =
    HoconAt(config.resolve(), path)

  def at(path: String): HoconAt =
    at(ConfigFactory.load())(path)
