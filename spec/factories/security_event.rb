FactoryBot.define do
  factory :security_event do
    event_type do
      %w[
        https://schemas.openid.net/secevent/risc/event-type/account-purged
        https://schemas.openid.net/secevent/risc/event-type/identifier-recycled
      ].sample
    end
    issued_at { Time.zone.now }
    uuid { SecureRandom.uuid }
    raw_event { {}.to_json }
  end
end
