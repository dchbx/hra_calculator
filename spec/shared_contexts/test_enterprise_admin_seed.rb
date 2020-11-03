# frozen_string_literal: true

RSpec.shared_context 'setup enterprise admin seed', shared_context: :metadata do
  let!(:enterprise) do
    new_enterprise = FactoryBot.create(:enterprise, owner_organization_name: 'OpenHBX')
    new_enterprise.options = [FactoryBot.build(:option)]
    new_enterprise.save!

    ::ResourceRegistry::AppSettings[:options].each do |option_hash|
      next option_hash if option_hash[:key] != :benefit_years

      option = FactoryBot.build(:option)
      option.assign_attributes(option_hash)

      option.child_options.each do |setting|
        new_enterprise.benefit_years = [FactoryBot.build(:benefit_year, expected_contribution: setting.default, calendar_year: setting.key.to_s.to_i, description: setting.description, is_active: true)]
      end
    end
    new_enterprise
  end

  let!(:benefit_year) { enterprise.benefit_years.first }
  let!(:owner_account) { FactoryBot.create(:account, email: 'admin@openhbx.org', role: 'Enterprise Owner', uid: 'admin@openhbx.org', enterprise_id: enterprise.id) }
end

RSpec.shared_context('setup tenant', shared_context: :metadata) do
  let!(:tenant) do
    create_tenant = ::Transactions::CreateTenant.new
    result = create_tenant.with_step_args(fetch: [enterprise: enterprise]).call(tenant_params)
    tenant = result.success
    options = tenant.sites.first.features.first.options.first.options
    options.first.update_attributes!(value: value_for_age_rated)
    options.second.update_attributes!(value: value_for_geo_rating_area)
    tenant
  end
end
