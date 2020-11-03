# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'spec/shared_contexts/test_enterprise_admin_seed')

RSpec.describe Api::ConfigurationsController, dbclean: :after_each do
  include_context 'setup enterprise admin seed'
  let!(:tenant_account) { FactoryBot.create(:account, email: 'admin@market_place.org', enterprise_id: enterprise.id) }
  let(:header_footer_config_keys) { ["marketplace_name", "marketplace_website_url", "call_center_phone", "site_logo", "benefit_year", "colors", "show_plan_in_results"] }

  describe 'tenant with age_rated and single geographic rating area' do
    let(:tenant_params) do
      { key: :dc, owner_organization_name: 'DC Marketplace', account_email: tenant_account.email }
    end
    let(:value_for_age_rated) { 'age_rated' }
    let(:value_for_geo_rating_area) { 'single' }
    include_context 'setup tenant'

    context 'default_configuration' do
      before do
        token = HraClientSession.issue
        request.headers["Authorization"] = "Bearer #{token}"
        get :default_configuration, params: {tenant: tenant.key}
      end

      it 'should be successful' do
        expect(response).to have_http_status(:success)
      end

      it 'should return response in JSON format' do
        expect{JSON.parse(response.body)}.not_to raise_error
      end

      context 'for response data' do
        before do
          @result = JSON.parse(response.body)
        end

        it 'should have success status' do
          expect(@result['status']).to eq('success')
        end

        it 'should have success status' do
          expect(@result['data'].class).to eq(::Hash)
        end

        it 'should have all the keys for the data' do
          attr_keys = @result['data'].keys
          HraDefaulter.schema.keys.map(&:name).map(&:to_s).each do |keyy|
            next keyy if ["start_month_dates", "end_month_dates"].include?(keyy)
            expect(attr_keys.include?(keyy)).to be_truthy
          end
        end

        it 'should have all the values for the data' do
          @result['data'].values.each do |value|
            expect(value).not_to be_nil
          end
        end
      end
    end

    context 'header_footer_config' do
      before do
        token = HraClientSession.issue
        request.headers["Authorization"] = "Bearer #{token}"
        get :header_footer_config, params: {tenant: tenant.key}
      end

      it 'should be successful' do
        expect(response).to have_http_status(:success)
      end

      it 'should return response in JSON format' do
        expect{JSON.parse(response.body)}.not_to raise_error
      end

      context 'for response data' do
        before do
          @result = JSON.parse(response.body)
        end

        it 'should have success status' do
          expect(@result['status']).to eq('success')
        end

        it 'should have success status' do
          expect(@result['data'].class).to eq(::Hash)
        end

        it 'should have the keys for the data' do
          expect(@result['data'].keys).to eq(header_footer_config_keys)
        end
      end
    end
  end

  describe 'tenant with age_rated and zipcode geographic rating area' do
    let(:tenant_params) do
      { key: :ma, owner_organization_name: 'MA Marketplace', account_email: tenant_account.email }
    end
    let(:value_for_age_rated) { 'age_rated' }
    let(:value_for_geo_rating_area) { 'zipcode' }
    include_context 'setup tenant'

    let(:countyzip) { FactoryBot.create(:locations_county_zip) }

    context 'default_configuration' do
      before do
        token = HraClientSession.issue
        request.headers["Authorization"] = "Bearer #{token}"
        get :default_configuration, params: {tenant: tenant.key}
      end

      it 'should be successful' do
        expect(response).to have_http_status(:success)
      end

      it 'should return response in JSON format' do
        expect{JSON.parse(response.body)}.not_to raise_error
      end

      context 'for response data' do
        before do
          @result = JSON.parse(response.body)
        end

        it 'should have success status' do
          expect(@result['status']).to eq('success')
        end

        it 'should have success status' do
          expect(@result['data'].class).to eq(::Hash)
        end

        it 'should have all the keys for the data' do
          attr_keys = @result['data'].keys
          HraDefaulter.schema.keys.map(&:name).map(&:to_s).each do |keyy|
            next keyy if ["start_month_dates", "end_month_dates"].include?(keyy)
            expect(attr_keys.include?(keyy)).to be_truthy
          end
        end

        it 'should have all the values for the data' do
          @result['data'].values.each do |value|
            expect(value).not_to be_nil
          end
        end
      end
    end

    context 'counties' do
      let(:countyzipcode) { FactoryBot.create(:locations_county_zip) }

      before do
        token = HraClientSession.issue
        request.headers["Authorization"] = "Bearer #{token}"
        get :counties, params: {hra_zipcode: countyzipcode.zip.to_s, tenant: tenant.key}
      end

      it 'should be successful' do
        expect(response).to have_http_status(:success)
      end

      it 'should return response in JSON format' do
        expect{JSON.parse(response.body)}.not_to raise_error
      end

      context 'for response data' do
        before do
          @result = JSON.parse(response.body)
        end

        it 'should have success status' do
          expect(@result['status']).to eq('success')
        end

        it 'should have success status' do
          expect(@result['data'].class).to eq(::Hash)
        end

        it 'should have the key for the data' do
          expect(@result['data'].keys).to eq(['counties'])
        end

        it 'should have all the values for the data' do
          expect(@result['data'].values.first).to eq([countyzipcode.county_name])
        end
      end
    end

    context 'header_footer_config' do
      before do
        token = HraClientSession.issue
        request.headers["Authorization"] = "Bearer #{token}"
        get :header_footer_config, params: {tenant: tenant.key}
      end

      it 'should be successful' do
        expect(response).to have_http_status(:success)
      end

      it 'should return response in JSON format' do
        expect{JSON.parse(response.body)}.not_to raise_error
      end

      context 'for response data' do
        before do
          @result = JSON.parse(response.body)
        end

        it 'should have success status' do
          expect(@result['status']).to eq('success')
        end

        it 'should have success status' do
          expect(@result['data'].class).to eq(::Hash)
        end

        it 'should have the keys for the data' do
          expect(@result['data'].keys).to eq(header_footer_config_keys)
        end
      end
    end
  end

  describe 'tenant with non_rated and county geographic rating area' do
    let(:tenant_params) do
      { key: :ny, owner_organization_name: 'NY Marketplace', account_email: tenant_account.email }
    end
    let(:value_for_age_rated) { 'non_age_rated' }
    let(:value_for_geo_rating_area) { 'county' }
    include_context 'setup tenant'

    let(:countyzip) { FactoryBot.create(:locations_county_zip, zip: nil, state: tenant.key.to_s.upcase) }

    context 'default_configuration' do
      before do
        token = HraClientSession.issue
        request.headers["Authorization"] = "Bearer #{token}"
        get :default_configuration, params: {tenant: tenant.key}
      end

      it 'should be successful' do
        expect(response).to have_http_status(:success)
      end

      it 'should return response in JSON format' do
        expect{JSON.parse(response.body)}.not_to raise_error
      end

      context 'for response data' do
        before do
          @result = JSON.parse(response.body)
        end

        it 'should have success status' do
          expect(@result['status']).to eq('success')
        end

        it 'should have success status' do
          expect(@result['data'].class).to eq(::Hash)
        end

        it 'should have all the keys for the data' do
          attr_keys = @result['data'].keys
          HraDefaulter.schema.keys.map(&:name).map(&:to_s).each do |keyy|
            next keyy if ["start_month_dates", "end_month_dates"].include?(keyy)
            expect(attr_keys.include?(keyy)).to be_truthy
          end
        end

        it 'should have all the values for the data' do
          @result['data'].values.each do |value|
            expect(value).not_to be_nil
          end
        end
      end
    end

    context 'header_footer_config' do
      before do
        token = HraClientSession.issue
        request.headers["Authorization"] = "Bearer #{token}"
        get :header_footer_config, params: {tenant: tenant.key}
      end

      it 'should be successful' do
        expect(response).to have_http_status(:success)
      end

      it 'should return response in JSON format' do
        expect{JSON.parse(response.body)}.not_to raise_error
      end

      context 'for response data' do
        before do
          @result = JSON.parse(response.body)
        end

        it 'should have success status' do
          expect(@result['status']).to eq('success')
        end

        it 'should have success status' do
          expect(@result['data'].class).to eq(::Hash)
        end

        it 'should have the keys for the data' do
          expect(@result['data'].keys).to eq(header_footer_config_keys)
        end
      end
    end
  end
end
