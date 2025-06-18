require 'rails_helper'

describe MembershipCsv do
  describe 'when rendering' do
    let(:view_stub) { instance_double ActionView::Base }

    describe 'with legacy users that do not have a role yet' do
      let(:memberships) do
        [build(:membership)]
      end

      it 'outputs a row with no role' do
        subject = described_class.new(memberships)
        expect(view_stub).to receive(:render) do |data|
          csv_response = CSV.parse(data[:body])
          expect(csv_response.length).to eq(2)
          expect(csv_response[0][2]).to eq('Team')
          expect(csv_response[1][2]).to eq(memberships[0].team.name)
          expect(csv_response[0][1]).to eq('Role')
          expect(csv_response[1][1]).to be_blank
        end
        subject.render_in(view_stub)
      end
    end
  end
end
