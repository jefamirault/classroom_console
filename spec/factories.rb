FactoryBot.define do
  factory :user do
    name { "John Doe" }
    email { "#{name.downcase.gsub(%r{\W}, '')}@example.com" }
  end
end