require 'env_settings/version'

module EnvSettings
  MissingSettingError = Class.new(StandardError)
  UnknownKeyError = Class.new(StandardError)

  class StringSetting

    def initialize(key, default: nil, required: default.nil?)
      @key = key
      @default = default
      @required = required
    end

    def extract(env)
      if @required
        unless env.has_key?(@key)
          raise MissingSettingError, "#{@key} must be set"
        end
      end

      env.fetch(@key, @default)
    end

  end

  class BooleanSetting

    def initialize(key, default: false, required: false)
      @string = StringSetting.new(key, default: default ? "yes" : "", required: required)
    end

    def extract(env)
      @string.extract(env).length > 0
    end

  end

  class ListSetting

    def initialize(key, default: [], delimiter: /\s*,\s*/, required: false)
      @string = StringSetting.new(key, default: "", required: required)
      @default = default
      @delimiter = delimiter
    end

    def extract(env)
      value = @string.extract(env)

      value.empty? ? @default : value.split(@delimiter)
    end

  end

  class CustomSetting

    def initialize(key, required: false, &extract_proc)
      @string = StringSetting.new(key, required: required)
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

    def extract(env)
      Settings.new(
        @settings.each_with_object({}) do |(key, setting), extracted|
          extracted[key] = setting.extract(env)
        end
      )
    end

  end

  def self.declare(&decl_block)
    Builder.new(&decl_block)
  end

  def self.extract(env = ENV, &decl_block)
    declare(&decl_block).extract(env)
  end

end
