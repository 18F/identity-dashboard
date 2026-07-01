require 'rails_helper'

describe Reports::Base do
  describe 'integrated with a report' do
    let(:analytic) do
      analytic = Analytic.new
      analytic.config = build(
        :service_provider,
        :ready_to_activate,
        issuer: 'urn:gov:gsa:openidconnect.profiles:sp:sso:dol_test',
      )
      analytic.date = '2025-12-01'
      analytic
    end

    let(:reports) { Reports.new(analytic) }

    subject { described_class.new(reports) }

    it 'can return the data #as_array_with_i18n_labels' do
      expected_data = [
        ['Newly Created Accounts', 1173], ['Existing Accounts', 346], ['Newly Proofed', 17],
        ['Previously Proofed', 30], ['Inauthentic Doc.', 475], ['Facial Mismatch', 82],
        ['Invalid Attributes (DL, DOS)', 500], ['Rejected for Invalid SSN / DOB, or Deceased', 12],
        ['Address / Not Found / Other', 163], ['Pending Fraud Review', 24],
        ['Stayed Blocked After Suspected Fraud', 27], ['Fraud Alert Detected', 2],
        ['Suspicious Phone', 1567], ['Lacking Phone Ownership', 1288], ['Wrong Phone Type', 317],
        ['Failed In-Person and Blocked', 0], ['Adjudicated as Legitimate', 22],
        ['Pass Online', 22330], ['Pass IPP (Online Portion)', 319], ['Pass via Letter', 0],
        ['Doc. Auth. UX Issue', 0], ['Selfie UX Issue', 54], ['DOB Incorrect', 65],
        ['SSN Incorrect', 186], ['Identity Not Found', 6], ['Friction during OTP', 59],
        ['Doc. Auth. Technical Issue', 0], ['Other Technical Issues', 0],
        ['Doc. Auth. Processing Issue', 2], ['Face / Touch', 38], ['Authenticator App', 71],
        ['PIV / CAC', 93], ['SMS', 284], ['Voice', 4], ['Backup Code', 2],
        ['Security Key', 8], ['Personal Key', 0]
      ]
      expect(subject.as_array_with_i18n_labels).to eq(expected_data)
    end

    it 'raises a NotImplementedError for #chart' do
      expect { subject.chart }.to raise_error(NotImplementedError)
    end
  end
end
