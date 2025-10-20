FactoryBot.define do
  factory :airtable do
    association :user # This assumes you have a user factory defined
    token { 'Token' }
    token_expiration { 1.day.from_now } # Example for token expiration (valid for 1 day)
    refresh_token { 'RefreshToken' }
    # Example for refresh token expiration (valid for 30 days)
    refresh_token_expiration do
      30.days.from_now
    end
    code_verifier { SecureRandom.hex(50) } # Random string for code verifier
  end
end
