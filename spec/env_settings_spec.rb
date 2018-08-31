RSpec.describe EnvSettings do
  let(:empty_env) { {} }

  def extract(env, &blk)
    described_class.extract(env, &blk)
  end

  context 'empty config' do

    it 'raises no error' do
      expect{
        described_class.extract(empty_env) {}
      }.not_to raise_error
    end

    it 'raises an error if you access a nonexistent setting' do
      settings = described_class.extract({
        "FOO" => "bar"
      }) {}
      expect{
        settings["FOO"]
      }.to raise_error(EnvSettings::UnknownKeyError)
    end

  end

  context 'string vars' do

    context 'if no default is provided' do

      it 'raises an error if missing' do
        expect{
          described_class.extract(empty_env) { |s|
            s.string "FOO"
          }
        }.to raise_error(EnvSettings::MissingSettingError)
      end

      it 'returns the provided value if present' do
        settings = described_class.extract({
          "FOO" => "bar"
        }) { |s|
          s.string "FOO"
        }
        expect(settings["FOO"]).to eq("bar")
      end

    end

    context 'if a default is provided' do

      it 'returns the default value if missing' do
        settings = described_class.extract({
        }) { |s|
          s.string "FOO", default: "bar"
        }
        expect(settings["FOO"]).to eq("bar")
      end

      it 'returns the provided value if present' do
        settings = described_class.extract({
          "FOO" => "bar"
        }) { |s|
          s.string "FOO", default: "not bar"
        }
        expect(settings["FOO"]).to eq("bar")
      end

    end

  end

  context 'boolean vars' do

    it 'interprets any non-blank string as true' do
      settings = described_class.extract({
        "FOO" => "bar"
      }) { |s|
        s.boolean "FOO"
      }
      expect(settings["FOO"]).to eq(true)
    end

    it 'interprets any non-blank string as true' do
      settings = described_class.extract({
        "FOO" => ""
      }) { |s|
        s.boolean "FOO"
      }
      expect(settings["FOO"]).to eq(false)
    end

    context 'if no default is provided' do

      it 'raises an error if missing' do
        expect{
          described_class.extract(empty_env) { |s|
            s.boolean "FOO"
          }
        }.to raise_error(EnvSettings::MissingSettingError)
      end

    end

    context 'if a default is provided' do

      it 'returns the default value if missing' do
        settings = described_class.extract({
        }) { |s|
          s.boolean "FOO", default: true
        }
        expect(settings["FOO"]).to eq(true)
      end

      it 'returns the provided value if present' do
        settings = described_class.extract({
          "FOO" => ""
        }) { |s|
          s.boolean "FOO", default: true
        }
        expect(settings["FOO"]).to eq(false)
      end

    end

  end

  context 'list vars' do

    it 'interprets a blank string as an empty list' do
      settings = described_class.extract({
        "FOO" => ""
      }) { |s|
        s.list "FOO"
      }
      expect(settings["FOO"]).to eq([])
    end

    it 'splits a non-blank string on whitespace-surrounded commas' do
      settings = described_class.extract({
        "FOO" => "foo, bar, baz  , bat"
      }) { |s|
        s.list "FOO"
      }
      expect(settings["FOO"]).to eq(%w[foo bar baz bat])
    end

    it 'splits a non-blank string on a provided delimiter' do
      settings = described_class.extract({
        "FOO" => "a:b:c:d"
      }) { |s|
        s.list "FOO", delimiter: /:/
      }
      expect(settings["FOO"]).to eq(%w[a b c d])
    end

    context 'if no default is provided' do

      it 'raises an error if missing' do
        expect{
          described_class.extract(empty_env) { |s|
            s.list "FOO"
          }
        }.to raise_error(EnvSettings::MissingSettingError)
      end

    end

    context 'if a default is provided' do

      it 'returns the default value if missing' do
        settings = described_class.extract({
        }) { |s|
          s.list "FOO", default: %w[foo bar]
        }
        expect(settings["FOO"]).to eq(%w[foo bar])
      end

      it 'returns the provided value if present' do
        settings = described_class.extract({
          "FOO" => "foo, bar"
        }) { |s|
          s.list "FOO", default: %w[baz bat]
        }
        expect(settings["FOO"]).to eq(%w[foo bar])
      end

    end

  end

end
