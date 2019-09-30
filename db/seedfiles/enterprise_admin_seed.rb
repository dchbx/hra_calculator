puts "::: Cleaning Database :::"
Enterprises::Enterprise.delete_all
Tenants::Tenant.delete_all
Account.delete_all

puts "::: Creating Enterprise admin :::"
enterprise = Enterprises::Enterprise.new(owner_organization_name: 'OpenHBX')

enterprise_option = Options::Option.new(key: 'owner_organization_name', default: 'My Organization', description: 'Name of the organization that manages', type: 'string')
enterprise.options = [enterprise_option]

enterprise.save!

owner_account = Account.new(email: 'admin@openhbx.org', role: 'Enterprise Owner', uid: 'admin@openhbx.org', password: 'ChangeMe!', enterprise_id: enterprise.id)
owner_account.save!

puts "::: Enterprise admin created :::"