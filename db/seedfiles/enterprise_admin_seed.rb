puts "::: Cleaning Database :::"
Enterprises::Enterprise.delete_all
Enterprises::BenefitYear.delete_all
Tenants::Tenant.delete_all
Locations::CountyZip.delete_all
Locations::RatingArea.delete_all
Locations::ServiceArea.delete_all
Account.delete_all
HraDetermination.delete_all

puts "::: Creating Enterprise admin :::"
enterprise = Enterprises::Enterprise.new(owner_organization_name: 'OpenHBX')

enterprise_option = Options::Option.new(key: 'owner_organization_name', default: 'My Organization', description: 'Name of the organization that manages', type: 'string')
enterprise.options = [enterprise_option]
enterprise.save!

ResourceRegistry::AppSettings[:options].each do |option_hash|
  if option_hash[:key] == :benefit_years
    option = Options::Option.new(option_hash)

    option.child_options.each do |setting|
      enterprise.benefit_years.create({ expected_contribution: setting.default, calendar_year: setting.key.to_s.to_i, description: setting.description, is_active: setting.is_active })
    end
  end
end

owner_account = Account.new(email: 'admin@openhbx.org', role: 'Enterprise Owner', uid: 'admin@openhbx.org', password: 'ChangeMe!', enterprise_id: enterprise.id)
owner_account.save!

puts "::: Enterprise admin created :::"
