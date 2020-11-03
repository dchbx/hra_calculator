class Enterprises::Enterprise
  include Mongoid::Document
  include Mongoid::Timestamps

  field :owner_organization_name, type: String
  field :show_plan_calculation_in_client_ui, type: Boolean, default: false

  has_one   :owner_account,
            class_name: 'Account'

  has_many  :tenants,
            class_name: 'Tenants::Tenant'

  has_many  :benefit_years, class_name: 'Enterprises::BenefitYear'

  embeds_many :options, as: :configurable,
              class_name: 'Options::Option'

  accepts_nested_attributes_for :tenants, :options

  def owner_account_name
    owner_account.email
  end
end
