require 'spec_helper'

class User
  include ActiveModel::Validations
  attr_accessor :password
end

class TestBaseStrength < User
  validates :password, password_strength: true
end

class TestStrengthWeakEntropy< User
  validates :password, password_strength: {min_entropy: 1, use_dictionary: true}
end

class TestStrengthStrongEntropy < User
  validates :password, password_strength: {min_entropy: 40, use_dictionary: true}
end

class TestStrengthExtraWords < User
  validates :password, password_strength: {extra_dictionary_words: ['mcmanus'], use_dictionary: true}
end

module ActiveModel
  module Validations
    describe PasswordStrengthValidator do
      let(:base_strength) { TestBaseStrength.new }
      let(:weak_entropy) { TestStrengthWeakEntropy.new }
      let(:strong_entropy) { TestStrengthStrongEntropy.new }
      let(:extra_words) { TestStrengthExtraWords.new }
      
      describe 'validations' do
        describe 'base strength' do
          describe 'invalid' do
            [
              'password',
              '1234',
              'f0bar',
              'b@s3'
            ].each do |password|
              it "adds errors when password is '#{password}'" do
                base_strength.password = password
                base_strength.valid?
                expect(base_strength.errors[:password]).to eq(["Password is too weak"])
              end
            end
          end
          
          describe 'valid' do
            [
              'p@ssw0fdsafsdafrd',
              'b@se3ball rocks',
              'f0bar plus baz',
              'b@s3_9123as##!1?'
            ].each do |password|
              it "does not add errors when password is '#{password}'" do
                base_strength.password = password
                base_strength.valid?
                expect(base_strength.errors[:password]).to be_empty
              end
            end
          end
        end
        
        describe 'entropy override' do
          describe 'lowered entropy' do
            describe 'valid' do
              [
                'password',
                '1234',
                'f0bar',
                'b@s3'
              ].each do |password|
                it "'#{password}' should be valid with lowered entropy requirement" do
                  weak_entropy.password = password
                  weak_entropy.valid?
                  expect(weak_entropy.errors[:password]).to be_empty
                end
              end
            end
          end
          
          describe 'increased entropy' do
            describe 'valid' do
              [
                'p@ssw0fdsafsdafrd',
                'b@se3ball rocks',
                'f0bar plus baz',
                'b@s3_9123as##!1?'
              ].each do |password|
                it "'#{password}' should be invalid with increased entropy requirement" do
                  strong_entropy.password = password
                  strong_entropy.valid?
                  expect(strong_entropy.errors[:password]).to eq(["Password is too weak"])
                end
              end
            end
          end
        end
        
        describe 'extra words' do
          it 'allows extra words to be specified as an option to the validation' do
            password = 'mcmanus'
            weak_entropy.password = password
            expect(weak_entropy.valid?).to be_true
            extra_words.password = password
            expect(extra_words.valid?).to be_false
          end
        end
      end
    end
  end
end