require 'rails_helper'

describe Report::Authentication do
  let(:mock_reports) do
    mock = instance_double(Reports)
    allow(mock).to receive(:data).and_return(test_data)
    mock
  end

  subject { described_class.new(mock_reports) }

  context 'with good data' do
    let(:test_data) do
      JSON.parse(Rails.root.join(
        'spec/fixtures/reports/v2/4388/monthly/2025-12-01.json',
      ).read)['data']
    end

    it 'returns the #success_rate' do
      expect(subject.success_rate).to be(96.44)
    end

    it 'returns the #account_creation_success_rate' do
      expect(subject.account_creation_success_rate).to be(100.0)
    end

    it 'returns an #mfa_chart of percentages, rounded' do
      expect(subject.mfa_chart).to eq({
        type: :bar_chart,
        data: [
          ['Face / Touch', 4.66],
          ['Authenticator App', 75.61],
          ['PIV / CAC', 0.68],
          ['SMS', 7.09],
          ['Voice', 0.0],
          ['Backup Code', 0.39],
          ['Security Key', 0.0],
          ['Personal Key', 0.0],
        ],
        options: {
          title: 'Multi-Factor Authentication (MFA) Type',
          library: {
            accessibility: { screenReaderSection: {
              beforeChartFormat: '<h2>Multi-Factor Authentication (MFA) Type</h2>',
            } },
            subtitle: { align: 'left', text: 'How users authenticated during this window' },
            title: { align: 'left' },
            caption: {
              useHTML: true,
              text: 'Percentage of successful sign-ins from MFA type' \
                ', out of all successful attempts.',
            },
            chart: { colorCount: 4, styledMode: true },
            plotOptions: { series: { animation: false, colorByPoint: true } },
            yAxis: { gridLineColor: '#888', minTickInterval: 1 },
          },
          max: 100,
          suffix: '%',
        },
      })
    end

    it 'returns a #device_type_chart of percentages, rounded' do
      expect(subject.device_type_chart).to include({
        type: :pie_chart,
        data: [['Desktop', 96.4], ['Mobile', 3.6]],
      })
      expect(subject.device_type_chart[:options]).to include({
        title: 'Device Type',
        donut: true,
        suffix: '%',
      })
      expect(subject.device_type_chart[:options][:library]).to include({
        subtitle: { align: 'left', text: 'How users accessed your service during this window' },
        accessibility: { screenReaderSection: { beforeChartFormat: '<h2>Device Type</h2>' } },
        chart: { colorCount: 4, styledMode: true },
      })
    end
  end

  context 'without authentication data' do
    let(:test_data) do
      { 'other_data' => rand(1..1000) }
    end

    it 'returns a nil #success_rate' do
      expect(subject.success_rate).to be_nil
    end

    it 'returns a nil #account_creation_success_rate' do
      expect(subject.account_creation_success_rate).to be_nil
    end

    it 'returns an empty #mfa_chart' do
      expect(subject.mfa_chart).to eq({
        type: :bar_chart,
        data: [],
        options: {
          title: 'Multi-Factor Authentication (MFA) Type',
          library: {
            accessibility: { screenReaderSection: {
              beforeChartFormat: '<h2>Multi-Factor Authentication (MFA) Type</h2>',
            } },
            subtitle: { align: 'left', text: 'How users authenticated during this window' },
            title: { align: 'left' },
            caption: {
              useHTML: true,
              text: 'Percentage of successful sign-ins from MFA type' \
                ', out of all successful attempts.',
            },
            chart: { colorCount: 4, styledMode: true },
            plotOptions: { series: { animation: false, colorByPoint: true } },
            yAxis: { gridLineColor: '#888', minTickInterval: 1 },
          },
          max: 100,
          suffix: '%',
        },
      })
    end

    it 'returns an empty #device_type_chart' do
      expect(subject.device_type_chart).to eq({
        type: :pie_chart,
        data: [],
        options: {
          title: 'Device Type',
          donut: true,
          suffix: '%',
          library: {
            accessibility: { screenReaderSection: { beforeChartFormat: '<h2>Device Type</h2>' } },
            chart: { colorCount: 4, styledMode: true },
            plotOptions: { series: { animation: false, colorByPoint: true } },
            subtitle: { align: 'left', text: 'How users accessed your service during this window' },
            title: { align: 'left' }, yAxis: { gridLineColor: '#888', minTickInterval: 1 },
            caption: {
              useHTML: true,
              text: 'Percentage of successful sign-ins from device type, out of all successful ' \
                'attempts.',
            }
          },
        },
      })
    end
  end
end
