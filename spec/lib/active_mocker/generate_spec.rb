# frozen_string_literal: true
require "spec_helper"
require "lib/active_mocker"

RSpec.describe ActiveMocker::Generate do
  describe ".new" do
    let(:not_found_dir) { File.join(File.expand_path("../test_mock_dir", __FILE__)) }

    before do
      ActiveMocker::Config.set do |config|
        config.model_dir        = File.join(File.expand_path("../", __FILE__))
        config.mock_dir         = not_found_dir
        config.error_verbosity  = 0
        config.progress_bar     = false
      end
    end

    before do
      FileUtils.rm_rf not_found_dir
    end

    after do
      FileUtils.rmdir not_found_dir
      ActiveMocker::Config.load_defaults
    end

    context "model_dir" do
      it "ActiveMocker::Config.model_dir is valid and will not raise" do
        described_class.new
      end

      it "when ActiveMocker::Config.model_dir is nil" do
        expect(ActiveMocker::Config).to receive(:model_dir).and_return(nil)
        expect { described_class.new }.to raise_error(ArgumentError, "model_dir is missing a valued value!")
      end

      it "when ActiveMocker::Config.model_dir is empty string" do
        expect(ActiveMocker::Config).to receive(:model_dir).at_least(:once).and_return("")
        expect { described_class.new }.to raise_error(ArgumentError, "model_dir is missing a valued value!")
      end

      it "when ActiveMocker::Config.model_dir cannot be found" do
        expect(ActiveMocker::Config).to receive(:model_dir).at_least(:once).and_return("path")
        expect { described_class.new }.to raise_error(ArgumentError, "model_dir is missing a valued value!")
      end
    end

    context "mock_dir" do
      it "when ActiveMocker::Config.mock_dir is nil" do
        expect(ActiveMocker::Config).to receive(:mock_dir).and_return(nil)
        expect { described_class.new }.to raise_error(ArgumentError, "mock_dir is missing a valued value!")
      end

      it "when ActiveMocker::Config.mock_dir is empty string" do
        expect(ActiveMocker::Config).to receive(:mock_dir).at_least(:once).and_return("")
        expect { described_class.new }.to raise_error(ArgumentError, "mock_dir is missing a valued value!")
      end

      context "when ActiveMocker::Config.mock_dir cannot be found it will be created" do
        it do
          expect(ActiveMocker::Config).to receive(:mock_dir).at_least(:once).and_return(not_found_dir)
          expect(Dir.exist?(not_found_dir)).to eq false
          described_class.new
          expect(Dir.exist?(not_found_dir)).to eq true
        end
      end

      context "when old mock exist" do
        let(:current_mock_path) { File.join(not_found_dir, "model_mock.rb") }
        let(:old_mock_path) { File.join(not_found_dir, "old_mock_from_deleted_model_mock.rb") }
        let(:models_dir) { File.join(File.expand_path("../../", __FILE__), "models") }

        before do
          stub_const("ActiveRecord::Base", class_double("ActiveRecord::Base"))
          FileUtils.mkdir_p(not_found_dir)
          File.open(old_mock_path, "w") { |w| w.write "" }
          File.open(current_mock_path, "w") { |w| w.write "" }
          ActiveMocker::Config.model_dir = models_dir

          # This will allow it to create a shell of a class
          allow(ActiveMocker::MockCreator).to receive(:enabled_partials_default) { [] }
        end

        it "delete all and only regenerates the ones with models" do
          expect { described_class.new.call }.to change { File.exist?(old_mock_path) }.from(true).to(false)
        end

        it "keeps around any mocks that have models" do
          expect(File.exist?(current_mock_path)).to eq true
          described_class.new.call
          expect(File.exist?(current_mock_path)).to eq true
        end
      end
    end

    describe "ActiveMocker::Config.disable_modules_and_constants" do
      before do
        ActiveMocker::Config.disable_modules_and_constants = set_to
        ActiveMocker::Config.progress_bar                  = false
        ActiveMocker::Config.single_model_path             = File.join(File.expand_path("../../", __FILE__), "models/model.rb")
      end

      context "when true" do
        let(:set_to) { true }
        it "#enabled_partials is missing modules_constants" do
          expect(ActiveMocker::MockCreator).
            to receive(:new).with(hash_including(enabled_partials: [:class_methods, :attributes, :scopes, :defined_methods, :associations]))
          described_class.new.call
        end
      end

      context "when false" do
        let(:set_to) { false }
        it "#enabled_partials is missing modules_constants" do
          expect(ActiveMocker::MockCreator).
            to receive(:new).with(hash_including(enabled_partials: [:modules_constants, :class_methods, :attributes, :scopes, :defined_methods, :associations]))
          described_class.new.call
        end
      end
    end

    describe "ActiveMocker::Config.mock_append_name" do
      before do
        ActiveMocker::Config.progress_bar      = false
        ActiveMocker::Config.single_model_path = File.join(File.expand_path("../../models", __FILE__), "model.rb")
      end

      context "defaults" do
        it "defaults to Mock" do
          expect(ActiveMocker::Config.mock_append_name).to eq "Mock"
        end

        it "passes the default to MockCreator" do
          expect(ActiveMocker::MockCreator).
            to receive(:new).with(hash_including(mock_append_name: "Mock"))
          described_class.new.call
        end
      end

      context "override" do
        it "passes the override to MockCreator" do
          ActiveMocker::Config.mock_append_name = "Blink"
          expect(ActiveMocker::MockCreator).
            to receive(:new).with(hash_including(mock_append_name: "Blink"))
          described_class.new.call
        end
      end
    end
  end
end
