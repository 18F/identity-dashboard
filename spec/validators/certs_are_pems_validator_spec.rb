require 'rails_helper'

class CertsTestRecord
  include ActiveModel::Validations
  attr_accessor :certs

  validates_with CertsArePemsValidator
end

RSpec.describe CertsArePemsValidator, type: 'model' do
  subject { CertsTestRecord.new }
  let(:valid_cert) do
    <<~CERT
      -----BEGIN CERTIFICATE-----
      MIIDAjCCAeoCCQDnptBMGdfBIjANBgkqhkiG9w0BAQsFADBCMQswCQYDVQQGEwJV
      UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHU2VhdHRsZTEMMAoGA1UE
      ChMDMThGMCAXDTE0MTAwODIzMzkzMVoYDzIxMDYwMTEyMjMzOTMxWjBCMQswCQYD
      VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHU2VhdHRsZTEM
      MAoGA1UEChMDMThGMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1zps
      ODzA7AHnls/NaICXSuBjyRbmEmDsoAl6YC/3ljBfG8POZre5wTeSjkPaj/h70ai5
      DEWrG3PyEJ0D6QqwNjReChq3AFSSnPLZeRu11N4UVvScJwCpRMs2LD93BBfFy8VU
      SQIOsPdrpy9ct31aNzYhi7LF3GBgIwcwq3SLxaF+YYDbbGqHZ8XkjrQlQlRGOPc8
      dcKcl0azNqSP4jAp83sw2NsKNPgDpI3PCs3H4C2q0RV/V+A4EIXi/3brAmnwKSOA
      JZ2ZAUIjHkv/Y1kk1TzAcy6s/V5f5Mxb4BjXxdAB18umI+EnfHLupV2fScOYY833
      AHSpuBiY+b7UfYPU5QIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQCrjv4rCw3Qhpyv
      konOP/Yufxj/SwkaZdanJCnbOvndRk2qO57FQU9qPwUJOu8kws8Xat+A+4ow2hQl
      C0b4OlifwrYcnBK/hDOcMOOH/d8na2bzOSg7lkHMOK3luELxPqsnkrszwtqAYs6K
      cLk2AEacrkAG0DVfOqYOGtUGUrx5QDYutX2kz24VcZ10so4IfRYI4EJX/tF46lqy
      dp6KaRxeVNQo21CGhfzeBSqgd0tRicu9uHzI57nxCLIzSQoLT5c6geCl5LJ7DxS2
      kaNiHglqe6GyLbbp3Y5q45xyBGPtJVT6kR6XqK4sEJPRgznbDn2NDx0Ef9mxHdVP
      e0sZY2CS
      -----END CERTIFICATE-----
    CERT
  end

  it 'accepts a blank certificate' do
    expect(subject).to allow_value(['']).for(:certs)
  end

  it 'fails if certificate is present but not x509' do
    expect(subject).to_not allow_value(['foo']).for(:certs)
  end

  it 'provides an error message if certificate is present but not x509' do
    subject.certs = ['foo']
    subject.valid?
    expect(subject.errors[:certs]).to include('Certificate is not PEM-encoded')
  end

  it 'accepts a valid x509 certificate' do
    expect(subject).to allow_value([valid_cert]).for(:certs)
  end

  it 'rejects data that are not base64 encoded' do
    expect(subject).to_not allow_value(['', 'NOT A CERT']).for(:certs)
  end

  it 'rejects data that are base64 but still not a cert' do
    expect(subject).to_not allow_value(
      ["----BEGIN CERTIFICATE----\nCg==\n----END CERTIFICATE----"],
    ).for(:certs)
  end

  it 'rejects DER encoded certs' do
    der_cert = OpenSSL::X509::Certificate.new(build_pem).to_der
    expect(subject).to_not allow_value([der_cert]).for(:certs)
  end

  it 'rejects private keys as PEMs' do
    private_key_pem = OpenSSL::PKey::RSA.new(2048).to_pem
    expect(subject).to_not allow_value([private_key_pem]).for(:certs)
  end
end
