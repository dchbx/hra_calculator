# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'spec/shared_contexts/test_enterprise_admin_seed')

describe ::Transactions::DetermineAffordability, dbclean: :after_each do
  include_context 'setup enterprise admin seed'

  let!(:tenant_account) { FactoryBot.create(:account, email: 'admin@market_place.org', enterprise_id: enterprise.id) }

  describe 'tenant with age_rated and zipcode' do
    let(:tenant_params) do
      { key: :ma, owner_organization_name: 'MA Marketplace', account_email: tenant_account.email }
    end

    let(:value_for_age_rated) { 'age_rated' }
    let(:value_for_geo_rating_area) { 'zipcode' }

    include_context 'setup tenant'

    let!(:product1) do
      product = FactoryBot.create(:products_health_product, tenant: tenant, application_period: Date.new(Enterprises::BenefitYear.first.calendar_year, 1, 1)..Date.new(Enterprises::BenefitYear.first.calendar_year, 12, 31))
      product&.service_area&.update_attributes!(active_year: Enterprises::BenefitYear.first.calendar_year)
      product.premium_tables.each { |pt| pt&.rating_area&.update_attributes!(active_year: Enterprises::BenefitYear.first.calendar_year) }
      product
    end

    let(:countyzip) { ::Locations::CountyZip.find(product1.premium_tables.first.rating_area.county_zip_ids.first.to_s) }

    let(:valid_params) do
      {
        tenant: :ma, state: 'Massachusetts', dob: '2000-10-10', household_frequency: 'annually',
        household_amount: 10000, hra_type: 'ichra', start_month: "#{Enterprises::BenefitYear.first.calendar_year}-1-1", end_month: "#{Enterprises::BenefitYear.first.calendar_year}-12-1",
        hra_frequency: 'monthly', hra_amount: 100, zipcode: countyzip.zip, county: countyzip.county_name
      }
    end

    context 'with valid data' do
      context 'affordable' do
        before do
          @determined_result ||= subject.call(valid_params.merge!(household_amount: 1000000))
        end

        it 'should be successful' do
          expect(@determined_result.success?).to be_truthy
        end

        it 'should return a value that can be formatted to json' do
          expect { @determined_result.success.to_json }.not_to raise_error
        end

        context 'for response data' do
          before do
            @result ||= @determined_result.success
          end

          it 'should return a value of class Hash' do
            expect(@result.class).to eq(::Hash)
          end

          it 'should return affordable per given data' do
            expect(@result[:hra_determination]).to eq(:affordable)
          end

          it 'should not have any errors for given data' do
            expect(@result[:errors]).to be_empty
          end

          it 'should create HraDetermination object' do
            expect(::HraDetermination.all.count).to eq(1)
          end
        end
      end

      context 'unaffordable' do
        before do
          @determined_result ||= subject.call(valid_params)
        end

        it 'should be successful' do
          expect(@determined_result.success?).to be_truthy
        end

        it 'should return a value that can be formatted to json' do
          expect { @determined_result.success.to_json }.not_to raise_error
        end

        context 'for response data' do
          before do
            @result ||= @determined_result.success
          end

          it 'should return a value of class Hash' do
            expect(@result.class).to eq(::Hash)
          end

          it 'should return unaffordable per given data' do
            expect(@result[:hra_determination]).to eq(:unaffordable)
          end

          it 'should not have any errors for given data' do
            expect(@result[:errors]).to be_empty
          end

          it 'should create HraDetermination object' do
            expect(::HraDetermination.all.count).to eq(1)
          end
        end
      end
    end

    context 'with invalid data' do
      let(:invalid_params) do
        { state: '', dob: '2000-10-10', household_frequency: 'annually',
          household_amount: 10000, hra_type: 'ichra', start_month: "#{Enterprises::BenefitYear.first.calendar_year}-1-1", end_month: "#{Enterprises::BenefitYear.first.calendar_year}-12-1",
          hra_frequency: 'monthly', hra_amount: 100, zipcode: '', county: '' }
      end

      before do
        @determined_result ||= subject.call(invalid_params)
      end

      it 'should not be successful' do
        expect(@determined_result.success?).to be_falsey
      end

      it 'should return a value that can be formatted to json' do
        expect { @determined_result.failure.to_json }.not_to raise_error
      end

      context 'for response data' do
        before do
          @result ||= @determined_result.failure
        end

        it 'should return a value of class Hash' do
          expect(@result.class).to eq(::Hash)
        end

        it 'should have any errors for given data' do
          expect(@result[:errors]).not_to be_empty
        end
      end
    end
  end

  describe 'tenant with non_age_rated and county' do
    let(:tenant_params) do
      { key: :ny, owner_organization_name: 'NY Marketplace', account_email: tenant_account.email }
    end

    let(:value_for_age_rated) { 'non_age_rated' }
    let(:value_for_geo_rating_area) { 'county' }

    include_context 'setup tenant'

    let!(:product1) do
      product = FactoryBot.create(:products_health_product, tenant: tenant, application_period: Date.new(Enterprises::BenefitYear.first.calendar_year, 1, 1)..Date.new(Enterprises::BenefitYear.first.calendar_year, 12, 31))
      product&.service_area&.update_attributes!(active_year: Enterprises::BenefitYear.first.calendar_year, covered_states: ['NY'])
      product.premium_tables.each { |pt| pt&.rating_area&.update_attributes!(active_year: Enterprises::BenefitYear.first.calendar_year) }
      product
    end

    let(:countyzip) do
      county_zip = ::Locations::CountyZip.find(product1.premium_tables.first.rating_area.county_zip_ids.first.to_s)
      county_zip.update_attributes!(state: 'NY', county_name: 'New York', zip: nil)
      county_zip
    end

    let(:valid_params) do
      {
        tenant: :ny, state: 'New York', household_frequency: 'annually',
        household_amount: 10000, hra_type: 'ichra', start_month: "#{Enterprises::BenefitYear.first.calendar_year}-1-1", end_month: "#{Enterprises::BenefitYear.first.calendar_year}-12-1",
        hra_frequency: 'monthly', hra_amount: 100, county: countyzip.county_name
      }
    end

    context 'with valid data' do
      context 'affordable' do
        before do
          @determined_result ||= subject.call(valid_params.merge!(household_amount: 1000000))
        end

        it 'should be successful' do
          expect(@determined_result.success?).to be_truthy
        end

        it 'should return a value that can be formatted to json' do
          expect { @determined_result.success.to_json }.not_to raise_error
        end

        context 'for response data' do
          before do
            @result ||= @determined_result.success
          end

          it 'should return a value of class Hash' do
            expect(@result.class).to eq(::Hash)
          end

          it 'should return affordable per given data' do
            expect(@result[:hra_determination]).to eq(:affordable)
          end

          it 'should not have any errors for given data' do
            expect(@result[:errors]).to be_empty
          end

          it 'should create HraDetermination object' do
            expect(::HraDetermination.all.count).to eq(1)
          end
        end
      end

      context 'unaffordable' do
        before do
          @determined_result ||= subject.call(valid_params)
        end

        it 'should be successful' do
          expect(@determined_result.success?).to be_truthy
        end

        it 'should return a value that can be formatted to json' do
          expect { @determined_result.success.to_json }.not_to raise_error
        end

        context 'for response data' do
          before do
            @result ||= @determined_result.success
          end

          it 'should return a value of class Hash' do
            expect(@result.class).to eq(::Hash)
          end

          it 'should return unaffordable per given data' do
            expect(@result[:hra_determination]).to eq(:unaffordable)
          end

          it 'should not have any errors for given data' do
            expect(@result[:errors]).to be_empty
          end

          it 'should create HraDetermination object' do
            expect(::HraDetermination.all.count).to eq(1)
          end
        end
      end
    end

    context 'with invalid data' do
      let(:invalid_params) do
        { state: '', dob: '2000-10-10', household_frequency: 'annually',
          household_amount: 10000, hra_type: 'ichra', start_month: "#{Enterprises::BenefitYear.first.calendar_year}-1-1", end_month: "#{Enterprises::BenefitYear.first.calendar_year}-12-1",
          hra_frequency: 'monthly', hra_amount: 100, zipcode: '', county: '' }
      end

      before do
        @determined_result ||= subject.call(invalid_params)
      end

      it 'should not be successful' do
        expect(@determined_result.success?).to be_falsey
      end

      it 'should return a value that can be formatted to json' do
        expect { @determined_result.failure.to_json }.not_to raise_error
      end

      context 'for response data' do
        before do
          @result ||= @determined_result.failure
        end

        it 'should return a value of class Hash' do
          expect(@result.class).to eq(::Hash)
        end

        it 'should have any errors for given data' do
          expect(@result[:errors]).not_to be_empty
        end
      end
    end
  end

  describe 'tenant with age_rated and single' do
    let(:tenant_params) do
      { key: :dc, owner_organization_name: 'DC Marketplace', account_email: tenant_account.email }
    end

    let(:value_for_age_rated) { 'age_rated' }
    let(:value_for_geo_rating_area) { 'single' }

    include_context 'setup tenant'

    let!(:product1) do
      product = FactoryBot.create(:products_health_product, tenant: tenant, application_period: Date.new(Enterprises::BenefitYear.first.calendar_year, 1, 1)..Date.new(Enterprises::BenefitYear.first.calendar_year, 12, 31), service_area_id: nil)
      product.premium_tables.each { |pt| pt.update_attributes!(rating_area_id: nil) }
      product
    end

    let(:valid_params) do
      {
        tenant: :dc, state: 'District of Columbia', dob: '2000-10-10', household_frequency: 'annually',
        household_amount: 10000, hra_type: 'ichra', start_month: "#{Enterprises::BenefitYear.first.calendar_year}-1-1", end_month: "#{Enterprises::BenefitYear.first.calendar_year}-12-1",
        hra_frequency: 'monthly', hra_amount: 100
      }
    end

    context 'with valid data' do
      context 'affordable' do
        before do
          @determined_result ||= subject.call(valid_params.merge!(household_amount: 1000000))
        end

        it 'should be successful' do
          expect(@determined_result.success?).to be_truthy
        end

        it 'should return a value that can be formatted to json' do
          expect { @determined_result.success.to_json }.not_to raise_error
        end

        context 'for response data' do
          before do
            @result ||= @determined_result.success
          end

          it 'should return a value of class Hash' do
            expect(@result.class).to eq(::Hash)
          end

          it 'should return affordable per given data' do
            expect(@result[:hra_determination]).to eq(:affordable)
          end

          it 'should not have any errors for given data' do
            expect(@result[:errors]).to be_empty
          end

          it 'should create HraDetermination object' do
            expect(::HraDetermination.all.count).to eq(1)
          end
        end
      end

      context 'unaffordable' do
        before do
          @determined_result ||= subject.call(valid_params)
        end

        it 'should be successful' do
          expect(@determined_result.success?).to be_truthy
        end

        it 'should return a value that can be formatted to json' do
          expect { @determined_result.success.to_json }.not_to raise_error
        end

        context 'for response data' do
          before do
            @result ||= @determined_result.success
          end

          it 'should return a value of class Hash' do
            expect(@result.class).to eq(::Hash)
          end

          it 'should return unaffordable per given data' do
            expect(@result[:hra_determination]).to eq(:unaffordable)
          end

          it 'should not have any errors for given data' do
            expect(@result[:errors]).to be_empty
          end

          it 'should create HraDetermination object' do
            expect(::HraDetermination.all.count).to eq(1)
          end
        end
      end
    end

    context 'with invalid data' do
      let(:invalid_params) do
        { state: '', dob: '2000-10-10', household_frequency: 'annually',
          household_amount: 10000, hra_type: 'ichra', start_month: "#{Enterprises::BenefitYear.first.calendar_year}-1-1", end_month: "#{Enterprises::BenefitYear.first.calendar_year}-12-1",
          hra_frequency: 'monthly', hra_amount: 100, zipcode: '', county: '' }
      end

      before do
        @determined_result ||= subject.call(invalid_params)
      end

      it 'should not be successful' do
        expect(@determined_result.success?).to be_falsey
      end
      it 'should return a value that can be formatted to json' do
        expect { @determined_result.failure.to_json }.not_to raise_error
      end

      context 'for response data' do
        before do
          @result ||= @determined_result.failure
        end

        it 'should return a value of class Hash' do
          expect(@result.class).to eq(::Hash)
        end

        it 'should have any errors for given data' do
          expect(@result[:errors]).not_to be_empty
        end
      end
    end
  end
end
