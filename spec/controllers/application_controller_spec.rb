require 'rails_helper'

RSpec.describe ApplicationController do
  let(:user) { create(:user) }
  let(:trace_id) { 'some-trace-id-abcdef' }

  before do
    allow(controller).to receive(:current_user).and_return(user)

    request.headers['X-Amzn-Trace-Id'] = trace_id
  end

  describe '#append_info_to_payload' do
    let(:payload) { {} }

    it 'adds user_uuid, user_agent and ip, trace_id to the lograge output' do
      controller.append_info_to_payload(payload)

      expect(payload).to eq(
        user_uuid: user.uuid,
        user_agent: request.user_agent,
        ip: request.remote_ip,
        host: request.host,
        trace_id: trace_id,
      )
    end

    context 'when there is no current_user' do
      let(:current_user) { nil }

      it 'logs a nil user_uuid' do
        controller.append_info_to_payload(payload)

        expect(payload).to include(user_uuid: nil)
      end
    end

    context 'banners are shown at the appropriate times' do
      let(:current_banner_one) {
        build(:banner, start_date: Time.zone.now.beginning_of_day - 2.days,
                       end_date: Time.zone.now.beginning_of_day + 2.days)
      }
      let(:current_banner_two) {
        build(:banner, start_date: Time.zone.now.beginning_of_day - 10.days,
                       end_date: Time.zone.now.beginning_of_day + 2.days)
      }
      let(:current_banner_three) {
        build(:banner, start_date: Time.zone.now.beginning_of_day - 5.days)
      }

      let(:nil_start_and_end_date_banner) {
        build(:banner)
      }
      let(:ended_banner) {
        build(:banner, start_date: Time.zone.now.beginning_of_day - 2.days, 
                       end_date: Time.zone.now.beginning_of_day - 1.day)
      }

      before do 
        current_banner_one.save
        current_banner_two.save
        current_banner_three.save
        nil_start_and_end_date_banner.save
        ended_banner.save
      end

      it 'only includes active banners' do
        displayed_banners = subject.send(:get_banner_messages)
        expect(displayed_banners.count).to eq(4)

        expect(displayed_banners).to include(current_banner_one)
        expect(displayed_banners).to include(current_banner_two)
        expect(displayed_banners).to include(current_banner_three)
        expect(displayed_banners).to include(nil_start_and_end_date_banner)
        expect(displayed_banners).to_not include(ended_banner)
      end

      it 'orders the banners by start_date' do
        displayed_banners = subject.send(:get_banner_messages)
        
        expect(displayed_banners.first).to eq(nil_start_and_end_date_banner)
        expect(displayed_banners.second).to eq(current_banner_two)
        expect(displayed_banners.third).to eq(current_banner_three)
        expect(displayed_banners.fourth).to eq(current_banner_one)
      end

    end
  end
end
