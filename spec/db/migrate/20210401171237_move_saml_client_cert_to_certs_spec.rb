require 'rails_helper'

require Rails.root.join('db/migrate/20210401171237_move_saml_client_cert_to_certs.rb')

# This entire spec can be removed once the saml_client_cert column is dropped
RSpec.describe MoveSAMLClientCertToCerts do
  around do |ex|
    cols = ServiceProvider.ignored_columns;
    ServiceProvider.ignored_columns = []

    ex.run
  ensure
    ServiceProvider.ignored_columns = cols
  end

  it 'adds the singular saml_client_cert to the array certs column' do
    sp_both_nil = create(:service_provider, saml_client_cert: nil, certs: nil)
    sp_blank_string = create(:service_provider, saml_client_cert: '', certs: nil)
    sp_both_values = create(:service_provider,
                            saml_client_cert: build_pem(serial: 1),
                            certs: [build_pem(serial: 2), build_pem(serial: 3)])
    sp_only_singular = create(:service_provider, saml_client_cert: build_pem(serial: 4), certs: nil)
    sp_only_plural = create(:service_provider, saml_client_cert: nil, certs: [build_pem(serial: 5)])

    MoveSAMLClientCertToCerts.new.up

    aggregate_failures do
      expect(sp_both_nil.reload.certificates).to eq([])
      expect(sp_blank_string.reload.certificates).to eq([])
      expect(sp_both_values.reload.certificates.map(&:serial).map(&:to_i)).to eq([1, 2, 3])
      expect(sp_only_singular.reload.certificates.map(&:serial).map(&:to_i)).to eq([4])
      expect(sp_only_plural.reload.certificates.map(&:serial).map(&:to_i)).to eq([5])
    end
  end
end
