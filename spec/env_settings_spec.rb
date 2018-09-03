RSpec.describe EnvSettings do
  let(:empty_env) { {} }

  context '.load' do

    def load(env, &blk)
      described_class.load(env, &blk)
    end

    context 'empty config' do

      it 'raises no error' do
        expect{
          described_class.load(empty_env) {}
        }.not_to raise_error
      end

      it 'raises an error if you access a nonexistent setting' do
        settings = described_class.load({
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
            described_class.load(empty_env) { |s|
              s.string "FOO"
            }
          }.to raise_error(EnvSettings::MissingSettingError)
        end

        it 'returns the provided value if present' do
          settings = described_class.load({
            "FOO" => "bar"
          }) { |s|
            s.string "FOO"
          }
          expect(settings["FOO"]).to eq("bar")
        end

      end

      context 'if a default is provided' do

        it 'returns the default value if missing' do
          settings = described_class.load({
          }) { |s|
            s.string "FOO", default: "bar"
          }
          expect(settings["FOO"]).to eq("bar")
        end

        it 'returns the provided value if present' do
          settings = described_class.load({
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
        settings = described_class.load({
          "FOO" => "bar"
        }) { |s|
          s.boolean "FOO"
        }
        expect(settings["FOO"]).to eq(true)
      end

      it 'interprets any non-blank string as true' do
        settings = described_class.load({
          "FOO" => ""
        }) { |s|
          s.boolean "FOO"
        }
        expect(settings["FOO"]).to eq(false)
      end

      context 'if no default is provided' do

        it 'raises an error if missing' do
          expect{
            described_class.load(empty_env) { |s|
              s.boolean "FOO"
            }
          }.to raise_error(EnvSettings::MissingSettingError)
        end

      end

      context 'if a default is provided' do

        it 'returns the default value if missing' do
          settings = described_class.load({
          }) { |s|
            s.boolean "FOO", default: true
          }
          expect(settings["FOO"]).to eq(true)
        end

        it 'returns the provided value if present' do
          settings = described_class.load({
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
        settings = described_class.load({
          "FOO" => ""
        }) { |s|
          s.list "FOO"
        }
        expect(settings["FOO"]).to eq([])
      end

      it 'splits a non-blank string on whitespace-surrounded commas' do
        settings = described_class.load({
          "FOO" => "foo, bar, baz  , bat"
        }) { |s|
          s.list "FOO"
        }
        expect(settings["FOO"]).to eq(%w[foo bar baz bat])
      end

      it 'splits a non-blank string on a provided delimiter' do
        settings = described_class.load({
          "FOO" => "a:b:c:d"
        }) { |s|
          s.list "FOO", delimiter: /:/
        }
        expect(settings["FOO"]).to eq(%w[a b c d])
      end

      context 'if no default is provided' do

        it 'raises an error if missing' do
          expect{
            described_class.load(empty_env) { |s|
              s.list "FOO"
            }
          }.to raise_error(EnvSettings::MissingSettingError)
        end

      end

      context 'if a default is provided' do

        it 'returns the default value if missing' do
          settings = described_class.load({
          }) { |s|
            s.list "FOO", default: %w[foo bar]
          }
          expect(settings["FOO"]).to eq(%w[foo bar])
        end

        it 'returns the provided value if present' do
          settings = described_class.load({
            "FOO" => "foo, bar"
          }) { |s|
            s.list "FOO", default: %w[baz bat]
          }
          expect(settings["FOO"]).to eq(%w[foo bar])
        end

      end

    end

  end

  context '.extract' do

    def extract(env, &blk)
      described_class.extract(env, &blk)
    end

    it 'allows piecemeal sampling of ENV' do
      env = {
        "FOO_NAME" => "Margo McGee",
        "FOO_EMAIL" => "margo@example.com",
        "FOO_ENABLED" => "on",
        "FOO_SUPER_MODE" => "",
        "FOO_IDEAS" => "good, bad, kinda okay",
        "FOO_POWER_LEVELS" => "1:2:4:8",
      }
      extracted = extract(env) do |e|
        {
          name: e.string("FOO_NAME"),
          email: e.string("FOO_EMAIL"),
          type: e.string("FOO_TYPE", default: "frob"),
          enabled: e.boolean("FOO_ENABLED"),
          super_mode: e.boolean("FOO_SUPER_MODE", default: true),
          ideas: e.list("FOO_IDEAS"),
          zones: e.list("FOO_ZONES", default: %w[left right up down]),
          power_levels: e.custom("FOO_POWER_LEVELS") do |v|
            v.nil? ? [] : v.split(":").map(&:to_i).sort
          end,
        }
      end
      expect(extracted).to eq({
        name: "Margo McGee",
        email: "margo@example.com",
        type: "frob",
        enabled: true,
        super_mode: false,
        ideas: %w[good bad kinda\ okay],
        zones: %w[left right up down],
        power_levels: [1, 2, 4, 8],
      })
    end

  end

end
