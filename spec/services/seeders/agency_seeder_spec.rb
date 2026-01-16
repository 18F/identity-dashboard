require 'rails_helper'

RSpec.describe Seeders::AgencySeeder do
  let(:agency_configs) { Rails.application.config.agencies }

  subject(:agency_seeder) { described_class.new(agency_configs) }

  before do
    Agency.delete_all
  end

  describe '#run!' do
    it 'can seed the same data multiple times with no error' do
      agency_seeder.run!
      agency_seeder.run!

      last_id, last_attrs = agency_configs.to_a.last
      expect(Agency.find(last_id).name).to eq(last_attrs['name'])
    end

    context 'when trying to rename an agency to a name that already exists' do
      before do
        create(:agency, id: 1, name: 'some name')
      end

      let(:agency_configs) do
        {
          1 => { name: 'some other name' },
          2 => { name: 'some name' },
        }.with_indifferent_access
      end

      it 'renames everything correctly with no errors' do
        agency_seeder.run!

        agency1 = Agency.find(1)
        expect(agency1.name).to eq('some other name')

        agency2 = Agency.find(2)
        expect(agency2.name).to eq('some name')
      end
    end

    context 'when an extra agency outside the configuration exists in the database' do
      let!(:existing) { create(:agency, id: 1000, name: 'department of awesomeness') }

      it 'leaves existing records alone' do
        agency_seeder.run!

        expect(Agency.find(1000).name).to eq('department of awesomeness')
      end
    end

    context 'when an existing service provider to an agency by id foreign key' do
      let(:agency_configs) do
        {
          1 => { name: 'new name' },
        }.with_indifferent_access
      end

      before do
        agency = create(:agency, id: 1, name: 'original name')
        create(:service_provider, agency_id: agency.id, team: create(:team, agency:))
      end

      it 'does not violate the constraint by deleting' do
        agency_seeder.run!

        expect(Agency.find(1).name).to eq('new name')
      end
    end
  end
end
