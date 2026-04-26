require 'rails_helper'

RSpec.describe OnApiHelper do
  subject(:tester) { Class.new { include OnApiHelper }.new }

  let!(:setting) do
    AdminSetting.create!(
      on_api_path: 'https://oncampus.example.com/api',
      on_api_key: 'test_user',
      on_api_secret: 'test_secret',
      sis_school_year: '2025-2026',
      sis_level_num: 4
    )
  end

  let(:auth_response) do
    instance_double(
      Net::HTTPResponse,
      body: { 'Token' => 'fresh-bearer-token' }.to_json,
      code: '200'
    )
  end

  before do
    allow(tester).to receive(:on_authenticate).and_return(auth_response)
  end

  describe '#on_api_token' do
    it 'authenticates and persists the bearer token to admin_settings' do
      token = tester.on_api_token

      expect(token).to eq('fresh-bearer-token')
      setting.reload
      expect(setting.on_api_session_token).to eq('fresh-bearer-token')
      expect(setting.on_api_session_token_expires_at).to be_within(1.minute).of(20.minutes.from_now)
    end

    it 'reuses the cached token without re-authenticating' do
      tester.on_api_token

      expect(tester).not_to receive(:on_authenticate)
      expect(tester.on_api_token).to eq('fresh-bearer-token')
    end

    it 'refreshes when the stored token has expired' do
      setting.update!(
        on_api_session_token: 'stale-token',
        on_api_session_token_expires_at: 1.minute.ago
      )

      expect(tester.on_api_token).to eq('fresh-bearer-token')
      expect(setting.reload.on_api_session_token).to eq('fresh-bearer-token')
    end

    it 'refreshes when the stored token is within the 30s safety buffer' do
      setting.update!(
        on_api_session_token: 'about-to-expire',
        on_api_session_token_expires_at: 10.seconds.from_now
      )

      expect(tester.on_api_token).to eq('fresh-bearer-token')
    end
  end

  describe '#force_new_on_api_token' do
    it 're-authenticates even when the current token is still fresh' do
      setting.update!(
        on_api_session_token: 'still-good',
        on_api_session_token_expires_at: 19.minutes.from_now
      )

      expect(tester).to receive(:on_authenticate).and_return(auth_response)
      expect(tester.force_new_on_api_token).to eq('fresh-bearer-token')
      expect(setting.reload.on_api_session_token).to eq('fresh-bearer-token')
    end
  end

  describe '#on_api_get' do
    let(:get_response) do
      instance_double(Net::HTTPResponse, body: '[{"id":1}]', code: '200')
    end
    let(:http) { instance_double(Net::HTTP) }

    before do
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:request).and_return(get_response)
    end

    it 'fetches the token, attaches it to the URL, and returns the response' do
      captured_uri = nil
      allow(Net::HTTP::Get).to receive(:new) do |request_uri, _header|
        captured_uri = request_uri
        instance_double(Net::HTTP::Get).tap { |req| allow(req).to receive(:body=) }
      end

      response = tester.on_api_get('schoolinfo/allschoolyears')

      expect(response.code).to eq('200')
      expect(captured_uri).to include('t=fresh-bearer-token')
      expect(captured_uri).to include('/schoolinfo/allschoolyears')
      expect(setting.reload.on_api_session_token).to eq('fresh-bearer-token')
    end

    it 'returns a parsed JSON body when called via on_api_get_json' do
      allow(Net::HTTP::Get).to receive(:new).and_return(
        instance_double(Net::HTTP::Get, :body= => nil)
      )

      result = tester.on_api_get_json('schoolinfo/allschoolyears')
      expect(result).to eq([{ 'id' => 1 }])
    end
  end
end
