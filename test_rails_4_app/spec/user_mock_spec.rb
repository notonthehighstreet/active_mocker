# frozen_string_literal: true
require "spec_helper"
require_relative "../lib/post_methods"
require_mock "micropost_mock"
require_mock "user_mock"
require_mock "relationship_mock"
require_mock "account_mock"
require_relative "active_record_compatible_api"

describe UserMock do
  it_behaves_like "ActiveRecord", MicropostMock, AccountMock

  before(:each) do
    UserMock.clear_mock
    AccountMock.clear_mock
  end

  describe "::find_by_name" do
    it "will start the backtrace at the point where the method was called" do
      begin
        UserMock.find_by_name("name")
      rescue ActiveMocker::NotImplementedError => e
        expect(e.backtrace.first).to match(/\/.*\/spec\/user_mock_spec.rb/)
      end
    end

    it "raise descriptive error if not stubbed" do
      expect { UserMock.find_by_name("name") }.to raise_error("::find_by_name for Class: UserMock. To continue stub the method.")
    end
  end

  describe "has_many microposts" do
    subject { described_class.create }

    it do
      expect(subject.microposts.class).to eq ActiveMocker::HasMany
    end

    it do
      expect(subject.microposts.relation_class).to eq MicropostMock
    end

    it do
      expect(subject.microposts.foreign_key).to eq "user_id"
    end

    it do
      expect(subject.microposts.foreign_id).to eq subject.id
    end

    it "will set foreign_key with the foreign_id on all micropost" do
      user = described_class.create(microposts: [MicropostMock.create])
      expect(user.microposts.first.user_id).to eq user.id
    end
  end

  describe "has_many relationships" do
    subject { described_class.create }

    it do
      expect(subject.relationships.class).to eq ActiveMocker::HasMany
    end

    it do
      expect(subject.relationships.relation_class).to eq RelationshipMock
    end

    it do
      expect(subject.relationships.foreign_key).to eq "follower_id"
    end

    it do
      expect(subject.relationships.foreign_id).to eq subject.id
    end
  end

  describe "has_many followed_users" do
    subject { described_class.create }

    it do
      expect(subject.followed_users.class).to eq ActiveMocker::HasMany
    end

    it do
      expect(subject.followed_users.relation_class).to eq UserMock
    end

    it do
      expect(subject.followed_users.foreign_key).to eq "followed_id"
    end

    it do
      expect(subject.followed_users.foreign_id).to eq subject.id
    end
  end

  describe "has_many reverse_relationships" do
    subject { described_class.create }

    it do
      expect(subject.reverse_relationships.class).to eq ActiveMocker::HasMany
    end

    it do
      expect(subject.reverse_relationships.relation_class).to eq RelationshipMock
    end

    it do
      expect(subject.reverse_relationships.foreign_key).to eq "followed_id"
    end

    it do
      expect(subject.reverse_relationships.foreign_id).to eq subject.id
    end
  end

  describe "has one account" do
    it "will set the foreign_key from the objects id" do
      user = described_class.create(account: AccountMock.create)
      expect(user.account.user_id).to eq user.id
    end
  end

  describe "::mocked_class" do
    it "returns the name of the class being mocked" do
      expect(UserMock.send(:mocked_class)).to eq("User")
    end
  end

  describe "::column_names" do
    it "returns an array of column names found from the schema.rb file" do
      expect(UserMock.column_names).to eq(%w(id name email credits created_at updated_at password_digest remember_token admin))
    end
  end

  describe "mass_assignment" do
    it "can pass any or all attributes from schema in initializer" do
      result = UserMock.new(name: "Sam", email: "Walton")
      expect(result.name).to eq "Sam"
      expect(result.email).to eq "Walton"
    end

    it "will raise error if not an attribute or association" do
      expect { UserMock.new(baz: "Hello") }.to raise_error(ActiveMocker::UnknownAttributeError, "unknown attribute: baz")
    end
  end

  describe "relationships" do
    it "add instance methods from model relationships" do
      result = UserMock.new(followers: [1])
      expect(result.followers).to eq [1]
    end

    it "add has_many relationship" do
      expect(UserMock.new.microposts.count).to eq 0
      mock_inst = UserMock.new
      mock_inst.microposts << 1
      expect(mock_inst.microposts.count).to eq 1
      mock_inst.microposts << 1
      expect(mock_inst.microposts.count).to eq 2
      expect(mock_inst.microposts.to_a).to eq [1, 1]
    end
  end

  describe "instance methods" do
    it "will raise exception for Not Implemented methods" do
      expect(UserMock.new.method(:following?).parameters).to eq [[:req, :other_user]]
      expect { UserMock.new.following? }.to raise_error ArgumentError
      expect { UserMock.new.following?("foo") }.to raise_error(ActiveMocker::NotImplementedError, '#following? for Class: UserMock. To continue stub the method.')
    end

    it "can be implemented dynamically" do
      allow_any_instance_of(UserMock).to receive(:follow!) do |_this, other_user|
        "Now implemented with #{other_user}"
      end
      result = UserMock.new
      result = result.follow!("foo")
      expect(result).to eq "Now implemented with foo"
    end
  end

  describe "class methods" do
    it "will raise exception for Not Implemented methods" do
      expect { UserMock.new_remember_token }.to raise_error(ActiveMocker::NotImplementedError, "::new_remember_token for Class: UserMock. To continue stub the method.")
    end

    it "can be implemented as follows" do
      allow(UserMock).to receive(:new_remember_token) do
        "Now implemented"
      end
      expect(UserMock.new_remember_token).to eq("Now implemented")
    end
  end

  context "mock" do
    it "uses mock::base as superclass" do
      expect(UserMock.superclass.name).to eq "ActiveMocker::Base"
    end

    it "can save to class and then find instance by attribute" do
      record = UserMock.create(name: "Sam")
      expect(UserMock.find_by(name: "Sam")).to eq record
    end

    it '#update' do
      person = UserMock.create(name: "Justin")
      expect(UserMock.first.name).to eq "Justin"
      person.update(name: "Dustin")
      expect(UserMock.first.name).to eq "Dustin"

      expect(person.name).to eq "Dustin"
    end

    it "::destroy_all" do
      UserMock.create

      expect(UserMock.count).to eq 1

      UserMock.destroy_all

      expect(UserMock.count).to eq 0
    end

    it "::find_by" do
      person = UserMock.create(name: "dustin")
      expect(UserMock.find_by(name: "dustin")).to eq person
    end

    it "::find_or_create_by" do
      person = UserMock.find_or_create_by(name: "dustin")
      expect(UserMock.find_by(name: "dustin")).to eq person
      UserMock.find_or_create_by(name: "dustin")
      expect(UserMock.count).to eq 1
    end

    it "::find_or_create_by with update" do
      UserMock.create(name: "dustin")
      person = UserMock.find_or_create_by(name: "dustin")
      person.update(email: "Zeisler")
      expect(UserMock.first.attributes).to eq person.attributes
      expect(UserMock.count).to eq 1
    end

    it "::find_or_initialize_by" do
      person = UserMock.find_or_initialize_by(name: "dustin")
      expect(person.persisted?).to eq false
      UserMock.create(name: "dustin")
      person = UserMock.find_or_initialize_by(name: "dustin")
      expect(person.persisted?).to eq true
    end

    after(:each) do
      UserMock.delete_all
    end
  end
end
