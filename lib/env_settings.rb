require 'env_settings/version'

module EnvSettings
  MissingSettingError = Class.new(StandardError)
  UnknownKeyError = Class.new(StandardError)

  NO_DEFAULT = nil

  class StringSetting

    def initialize(key, default: NO_DEFAULT)
      @key = key
      @default = default
    end

    def extract(env)
      if @default == NO_DEFAULT
        unless env.has_key?(@key)
          raise MissingSettingError, "#{@key} must be set"
        end
      end

      env.fetch(@key, @default)
    end

  end

  class BooleanSetting

    def initialize(key, default: NO_DEFAULT)
      default = default == NO_DEFAULT ? NO_DEFAULT : (default ? "yes" : "")
      @string = StringSetting.new(key, default: default)
    end

    def extract(env)
      @string.extract(env).length > 0
    end

  end

  class NumberSetting

    def initialize(key, default: NO_DEFAULT)
      default = default == NO_DEFAULT ? NO_DEFAULT : default.to_s
      @string = StringSetting.new(key, default: default)
    end

    def extract(env)
      value = @string.extract(env)
      if value =~ /\./
        value.to_f
      else
        value.to_i
      end
    end

  end

  class ListSetting

    def initialize(key, default: NO_DEFAULT, delimiter: /\s*,\s*/)
      @default = default
      @string = StringSetting.new(key, default: default == NO_DEFAULT ? NO_DEFAULT : "")
      @delimiter = delimiter
    end

    def extract(env)
      value = @string.extract(env)

      if @default == NO_DEFAULT
        value.split(@delimiter)
      else
        value.empty? ? @default : value.split(@delimiter)
      end
    end

  end

  class CustomSetting

    def initialize(key, &extract_proc)
      @string = StringSetting.new(key)
      @extract_proc = extract_proc
    end

    def extract(env)
      @extract_proc.(@string.extract(env))
    end

  end

  class Settings

    def initialize(hash)
      @hash = hash
    end

    def [](key)
      @hash.fetch(key.to_s) {
        raise UnknownKeyError, "#{key} is not a configured env setting"
      }
    end

    def each(&blk)
      @hash.each(&blk)
    end

    def to_h
      @hash.each_with_object({}) do |(k, v), h|
        h[k.dup] = v.dup
      end
    end

  end

  class Builder

    def initialize
      @settings = {}
      yield self
    end

    def string(key, *args)
      key = key.to_s
      @settings[key] = StringSetting.new(key, *args)
    end

    def number(key, *args)
      key = key.to_s
      @settings[key] = NumberSetting.new(key, *args)
    end

    def boolean(key, *args)
      key = key.to_s
      @settings[key] = BooleanSetting.new(key, *args)
    end

    def list(key, *args)
      key = key.to_s
      @settings[key] = ListSetting.new(key, *args)
    end

    def custom(key, *args, &blk)
      key = key.to_s
      @settings[key] = CustomSetting.new(key, *args, &blk)
    end

    def load(env)
      Settings.new(
        @settings.each_with_object({}) do |(key, setting), extracted|
          extracted[key] = setting.extract(env)
        end
      )
    end

  end

  class Extractor

    def initialize(env)
      @env = env
    end

    def string(key, *args)
      key = key.to_s
      StringSetting.new(key, *args).extract(env)
    end

    def number(key, *args)
      key = key.to_s
      NumberSetting.new(key, *args).extract(env)
    end

    def boolean(key, *args)
      key = key.to_s
      BooleanSetting.new(key, *args).extract(env)
    end

    def list(key, *args)
      key = key.to_s
      ListSetting.new(key, *args).extract(env)
    end

    def custom(key, *args, &blk)
      key = key.to_s
      CustomSetting.new(key, *args, &blk).extract(env)
    end

    private

    attr_reader :env

  end

  def self.declare(&decl_block)
    Builder.new(&decl_block)
  end

  def self.load(env = ENV, &decl_block)
    declare(&decl_block).load(env)
  end

  def self.extract(env = ENV, &extract_block)
    yield Extractor.new(env)
  end

end
