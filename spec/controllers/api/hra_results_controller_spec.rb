# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'spec/shared_contexts/test_enterprise_admin_seed')

RSpec.describe Api::HraResultsController, :dbclean => :after_each do
  include_context 'setup enterprise admin seed'
  let!(:tenant_account) { FactoryBot.create(:account, email: 'admin@market_place.org', enterprise_id: enterprise.id) }

  describe 'tenant with age_rated and zipcode geographic rating model' do
    let(:tenant_params) do
      { key: :ma, owner_organization_name: 'MA Marketplace', account_email: tenant_account.email }
    end

    let(:value_for_age_rated) { 'age_rated' }
    let(:value_for_geo_rating_area) { 'zipcode' }

    include_context 'setup tenant'

    let!(:product) do
      product = FactoryBot.create(:products_health_product, tenant: tenant, application_period: Date.new(Enterprises::BenefitYear.first.calendar_year, 1, 1)..Date.new(Enterprises::BenefitYear.first.calendar_year, 12, 31))
      product&.service_area&.update_attributes!(active_year: Enterprises::BenefitYear.first.calendar_year)
      product.premium_tables.each { |pt| pt&.rating_area&.update_attributes!(active_year: Enterprises::BenefitYear.first.calendar_year) }
      product
    end

    let(:countyzip) { ::Locations::CountyZip.find(product.premium_tables.first.rating_area.county_zip_ids.first.to_s) }

    context 'hra_payload' do
      context 'valid params' do

        let(:valid_params) do
          { tenant: :ma, hra_result: { state: 'Massachusetts', dob: '2000-10-10', household_frequency: 'annually',
            household_amount: 10_000, hra_type: 'ichra', start_month: "#{Enterprises::BenefitYear.first.calendar_year}-1-1", end_month: "#{Enterprises::BenefitYear.first.calendar_year}-12-1",
            hra_frequency: 'monthly', hra_amount: 100, zipcode: countyzip.zip, county: countyzip.county_name } }
        end

        before do
          token = HraClientSession.issue
          request.headers["Authorization"] = "Bearer #{token}"
          get :hra_payload, params: valid_params
        end

        it 'should be successful' do
          expect(response).to have_http_status(:success)
        end

        it 'should return response in JSON format' do
          expect{JSON.parse(response.body)}.not_to raise_error
        end

        context 'for response data' do
          before do
            @result ||= JSON.parse(response.body)
          end

          it 'should have success status' do
            expect(@result['status']).to eq('success')
          end

          it 'should have success status' do
            expect(@result['data'].class).to eq(::Hash)
          end

          it 'should return unaffordable per given data' do
            expect(@result['data']['hra_determination']).to eq('unaffordable')
          end

          it 'should not have any errors for given data' do
            expect(@result['data']['errors']).to be_empty
          end
        end
      end

      context 'invalid params' do
        let(:invalid_params) do
          { tenant: :ma, hra_result: { state: '', dob: '2000-10-10', household_frequency: 'annually',
            household_amount: 10_000, hra_type: 'ichra', start_month: "#{Enterprises::BenefitYear.first.calendar_year}-1-1", end_month: "#{Enterprises::BenefitYear.first.calendar_year}-12-1",
            hra_frequency: 'monthly', hra_amount: 100, zipcode: countyzip.zip, county: countyzip.county_name } }
        end

        before do
          token = HraClientSession.issue
          request.headers["Authorization"] = "Bearer #{token}"
          get :hra_payload, params: invalid_params
        end

        it 'should be successful' do
          expect(response).to have_http_status(:success)
        end

        it 'should return response in JSON format' do
          expect{JSON.parse(response.body)}.not_to raise_error
        end

        context 'for response data' do
          before do
            @result ||= JSON.parse(response.body)
          end

          it 'should have failure status' do
            expect(@result['status']).to eq('failure')
          end

          it 'should return data in hash format' do
            expect(@result['data'].class).to eq(::Hash)
          end
        end
      end
    end
  end

  describe 'tenant with non_age_rated and county geographic rating model' do
    let(:tenant_params) do
      { key: :ny, owner_organization_name: 'NY Marketplace', account_email: tenant_account.email }
    end

    let(:value_for_age_rated) { 'non_age_rated' }
    let(:value_for_geo_rating_area) { 'county' }

    include_context 'setup tenant'

    let!(:product) do
      product = FactoryBot.create(:products_health_product, tenant: tenant, application_period: Date.new(Enterprises::BenefitYear.first.calendar_year, 1, 1)..Date.new(Enterprises::BenefitYear.first.calendar_year, 12, 31))
      product&.service_area&.update_attributes!(active_year: Enterprises::BenefitYear.first.calendar_year)
      product.premium_tables.each { |pt| pt&.rating_area&.update_attributes!(active_year: Enterprises::BenefitYear.first.calendar_year) }
      product
    end

    let(:countyzip) do
      county_zip = ::Locations::CountyZip.find(product.premium_tables.first.rating_area.county_zip_ids.first.to_s)
      county_zip.update_attributes!(state: 'NY', county_name: 'New York', zip: nil)
      county_zip
    end

    context 'hra_payload' do
      context 'valid params' do

        let(:valid_params) do
          { tenant: :ny, hra_result: { state: 'New York', dob: '2000-10-10', household_frequency: 'annually',
            household_amount: 10_000, hra_type: 'ichra', start_month: "#{Enterprises::BenefitYear.first.calendar_year}-1-1", end_month: "#{Enterprises::BenefitYear.first.calendar_year}-12-1",
            hra_frequency: 'monthly', hra_amount: 100, county: countyzip.county_name } }
        end

        before do
          product.service_area.update_attributes!(county_zip_ids: [countyzip.id])
          token = HraClientSession.issue
          request.headers["Authorization"] = "Bearer #{token}"
          get :hra_payload, params: valid_params
        end

        it 'should be successful' do
          expect(response).to have_http_status(:success)
        end

        it 'should return response in JSON format' do
          expect{JSON.parse(response.body)}.not_to raise_error
        end

        context 'for response data' do
          before do
            @result ||= JSON.parse(response.body)
          end

          it 'should have success status' do
            expect(@result['status']).to eq('success')
          end

          it 'should have success status' do
            expect(@result['data'].class).to eq(::Hash)
          end

          it 'should return unaffordable per given data' do
            expect(@result['data']['hra_determination']).to eq('unaffordable')
          end

          it 'should not have any errors for given data' do
            expect(@result['data']['errors']).to be_empty
          end
        end
      end

      context 'invalid params' do
        let(:invalid_params) do
          { tenant: :ma, hra_result: { state: '', dob: '2000-10-10', household_frequency: 'annually',
            household_amount: 10_000, hra_type: 'ichra', start_month: "#{Enterprises::BenefitYear.first.calendar_year}-1-1", end_month: "#{Enterprises::BenefitYear.first.calendar_year}-12-1",
            hra_frequency: 'monthly', hra_amount: 100, zipcode: countyzip.zip, county: countyzip.county_name } }
        end

        before do
          token = HraClientSession.issue
          request.headers["Authorization"] = "Bearer #{token}"
          get :hra_payload, params: invalid_params
        end

        it 'should be successful' do
          expect(response).to have_http_status(:success)
        end

        it 'should return response in JSON format' do
          expect{JSON.parse(response.body)}.not_to raise_error
        end

        context 'for response data' do
          before do
            @result ||= JSON.parse(response.body)
          end

          it 'should have failure status' do
            expect(@result['status']).to eq('failure')
          end

          it 'should return data in hash format' do
            expect(@result['data'].class).to eq(::Hash)
          end
        end
      end
    end
  end

  describe 'tenant with age_rated and single geographic rating model' do
    let(:tenant_params) do
      { key: :dc, owner_organization_name: 'DC Marketplace', account_email: tenant_account.email }
    end

    let(:value_for_age_rated) { 'age_rated' }
    let(:value_for_geo_rating_area) { 'single' }

    include_context 'setup tenant'

    let!(:product) do
      product = FactoryBot.create(:products_health_product, tenant: tenant, application_period: Date.new(Enterprises::BenefitYear.first.calendar_year, 1, 1)..Date.new(Enterprises::BenefitYear.first.calendar_year, 12, 31), service_area_id: nil)
      product.premium_tables.each { |pt| pt.update_attributes!(rating_area_id: nil) }
      product
    end

    context 'hra_payload' do
      context 'valid params' do
        let(:valid_params) do
          { tenant: :dc, hra_result: { state: 'District of Columbia', dob: '2000-10-10', household_frequency: 'annually',
            household_amount: 10_000, hra_type: 'ichra', start_month: "#{Enterprises::BenefitYear.first.calendar_year}-1-1", end_month: "#{Enterprises::BenefitYear.first.calendar_year}-1-1",
            hra_frequency: 'monthly', hra_amount: 100 } }
        end

        before do
          token = HraClientSession.issue
          request.headers["Authorization"] = "Bearer #{token}"
          get :hra_payload, params: valid_params
        end

        it 'should be successful' do
          expect(response).to have_http_status(:success)
        end

        it 'should return response in JSON format' do
          expect{JSON.parse(response.body)}.not_to raise_error
        end

        context 'for response data' do
          before do
            @result ||= JSON.parse(response.body)
          end

          it 'should have success status' do
            expect(@result['status']).to eq('success')
          end

          it 'should have success status' do
            expect(@result['data'].class).to eq(::Hash)
          end

          it 'should return unaffordable per given data' do
            expect(@result['data']['hra_determination']).to eq('unaffordable')
          end

          it 'should not have any errors for given data' do
            expect(@result['data']['errors']).to be_empty
          end
        end
      end

      context 'invalid params' do
        let(:invalid_params) do
          { tenant: :dc, hra_result: { state: '', dob: '2000-10-10', household_frequency: 'annually',
            household_amount: 10_000, hra_type: 'ichra', start_month: "#{Enterprises::BenefitYear.first.calendar_year}-1-1", end_month: "#{Enterprises::BenefitYear.first.calendar_year}-12-1",
            hra_frequency: 'monthly', hra_amount: 100 } }
        end

        before do
          token = HraClientSession.issue
          request.headers["Authorization"] = "Bearer #{token}"
          get :hra_payload, params: invalid_params
        end

        it 'should be successful' do
          expect(response).to have_http_status(:success)
        end

        it 'should return response in JSON format' do
          expect{JSON.parse(response.body)}.not_to raise_error
        end

        context 'for response data' do
          before do
            @result ||= JSON.parse(response.body)
          end

          it 'should have failure status' do
            expect(@result['status']).to eq('failure')
          end

          it 'should return data in hash format' do
            expect(@result['data'].class).to eq(::Hash)
          end
        end
      end
    end
  end
end
