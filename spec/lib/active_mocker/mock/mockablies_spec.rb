# frozen_string_literal: true
require "spec_helper"
require "active_mocker/mock/exceptions"
require "active_mocker/deprecated_components/mock_abilities"

describe ActiveMocker::MockAbilities do
  subject { described_class }

  describe "mocking class methods" do
    before do
      class TestClass
        include ActiveMocker::MockAbilities

        def self.buz
          call_mock_method(method: __method__, caller: caller, arguments: [])
        end

        def pop
          "pop!"
        end
      end
    end

    it "" do
      TestClass.mock_class_method(:buz) do
        "wiz"
      end

      expect(TestClass.buz).to eq "wiz"
    end
  end

  describe "binding" do
    before do
      class TestableBinding
        include ActiveMocker::MockAbilities

        def buz
          call_mock_method(method: __method__, caller: caller)
        end

        def self.baz
          call_mock_method(method: __method__, caller: caller)
        end

        def self.pop
          "!pop!"
        end

        def pop
          "pop!"
        end
      end
    end

    context "class" do
      let(:local_method) { "pop" }

      it "to block creation" do
        TestableBinding.mock_class_method(:baz) do
          local_method
        end

        expect(TestableBinding.baz).to eq "pop"
      end

      it "to block execution" do
        TestableBinding.mock_class_method(:baz, true) do
          pop
        end

        expect(TestableBinding.baz).to eq "!pop!"
      end
    end

    context "instance" do
      let(:local_method) { "pop" }

      context "to block creation" do
        it "at the class level" do
          TestableBinding.mock_instance_method(:buz) do
            local_method
          end
          expect(TestableBinding.new.buz).to eq "pop"
        end

        it "at the instance level" do
          test_binding = TestableBinding.new
          test_binding.mock_instance_method(:buz) do
            local_method
          end
          expect(test_binding.buz).to eq "pop"
        end
      end

      it "to block execution" do
        TestableBinding.mock_instance_method(:buz, true) do
          pop
        end

        expect(TestableBinding.new.buz).to eq "pop!"
      end
    end
  end

  describe "Mocking hierarchy" do
    before do
      class TestHierarchy
        include ActiveMocker::MockAbilities

        def buz
          call_mock_method(method: __method__, caller: caller)
        end

        def pop
          "pop!"
        end
      end
    end

    it "instance overrides class" do
      TestHierarchy.mock_class_method(:buz) do
        "wiz"
      end

      test_hierarchy = TestHierarchy.new
      test_hierarchy.mock_instance_method(:buz) do
        "buz"
      end

      expect(test_hierarchy.buz).to eq "buz"
    end
  end

  describe "mocking class and instance together" do
    before do
      class TestBoth
        include ActiveMocker::MockAbilities

        def zip
          call_mock_method(method: __method__, caller: caller)
        end

        def self.wiz
          call_mock_method(method: __method__, caller: caller)
        end
      end
    end

    it "can do it" do
      TestBoth.mock_class_method("wiz") { "Gee" }
      TestBoth.mock_instance_method("zip") { "zap" }
      expect(TestBoth.wiz).to eq("Gee")
      expect(TestBoth.new.zip).to eq("zap")
    end
  end

  describe "Arguments" do
    before do
      class WithArgs
        include ActiveMocker::MockAbilities

        def foo(stuff, other = nil)
          call_mock_method(method: __method__, caller: caller, arguments: [stuff, other])
        end

        def pop
          "pop!"
        end

        def self.fiz(buz)
          call_mock_method(method: __method__, caller: caller, arguments: [buz])
      end
      end
    end

    it "will send arguments in class method" do
      WithArgs.mock_class_method(:fiz) { |buz| buz }

      expect(WithArgs.fiz("pop")).to eq "pop"
    end

    it "arguments with instance binding" do
      WithArgs.mock_instance_method(:foo, true) do |stuff, other = nil|
        "#{stuff} - #{other} - #{pop}"
      end

      expect(WithArgs.new.foo("stuff")).to eq "stuff -  - pop!"
    end

    it "optional value not used" do
      WithArgs.mock_instance_method(:foo) do |stuff, other = nil|
        "#{stuff} - #{other}"
      end

      expect(WithArgs.new.foo("stuff")).to eq "stuff - "
    end

    it "optional value used" do
      WithArgs.mock_instance_method(:foo) do |stuff, other = nil|
        "#{stuff} - #{other}"
      end

      expect(WithArgs.new.foo("stuff", "other")).to eq "stuff - other"
    end
  end

  describe '#clear_mocked_methods' do
    before do
      class TestClearInstance
        include ActiveMocker::MockAbilities

        def buz
          call_mock_method(__method__, caller, [])
        end
      end
    end

    it "will clear all instance method mocks" do
      test_clear = TestClearInstance.new
      test_clear.mock_instance_method(:buz) {}
      test_clear.clear_mocked_methods
      expect { test_clear.buz }.to raise_error(ArgumentError)
    end
  end

  describe ".clear_mocked_methods" do
    before do
      class TestClearInstance
        include ActiveMocker::MockAbilities

        def buz
          call_mock_method(__method__, caller, [])
        end

        def self.pop
          call_mock_method(__method__, caller, [])
        end
      end
    end

    it "will clear all instance and class method mocks" do
      test_clear = TestClearInstance.new
      TestClearInstance.mock_instance_method(:buz) {}
      TestClearInstance.mock_class_method(:pop) {}
      TestClearInstance.clear_mocked_methods
      expect { test_clear.buz }.to raise_error(ArgumentError)
      expect { TestClearInstance.pop }.to raise_error(ArgumentError)
    end
  end

  describe "if method has not been mocked it will raise" do
    before do
      class TestRaise
        include ActiveMocker::MockAbilities

        def buz
          call_mock_method(method: __method__, caller: caller, arguments: [])
        end

        def self.pop
          call_mock_method(method: __method__, caller: caller, arguments: [])
        end
      end
    end

    it "will raise if unmocked class method is called" do
      expect { TestRaise.pop }.to raise_error(ActiveMocker::NotImplementedError, "::pop for Class: TestRaise. To continue stub the method.")
    end

    it "will start the backtrace at the point where the method was called" do
      begin
        TestRaise.pop
      rescue ActiveMocker::NotImplementedError => e
        expect(e.backtrace.first).to match(/active_mocker\/mock\/mockablies_spec.rb/)
      end
    end

    it "will raise if unmocked instance method is called" do
      expect { TestRaise.new.buz }.to raise_error(ActiveMocker::NotImplementedError, '#buz for Class: TestRaise. To continue stub the method.')
    end
  end
end
