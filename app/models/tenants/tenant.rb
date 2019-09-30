class Tenants::Tenant
  include Mongoid::Document
  include Mongoid::Timestamps

  field :key, type: Symbol
  field :owner_organization_kind, type: String, default: 'Marketplace'
  field :owner_organization_name, type: String

  belongs_to :enterprise,
             class_name: 'Enterprises::Enterprise'

  has_many  :owner_accounts,
            class_name: 'Account'

  has_many  :sites,
            class_name: 'Sites::Site'

  embeds_many :options, as: :configurable,
              class_name: 'Options::Option'

  accepts_nested_attributes_for :sites, :options

  def has_service_area_constraints?
    (key == :ma) ? true : false
  end

  def has_rating_area_constraints?
    (key == :ma) ? true : false
  end

  def zipcode_constraints?
    (key == :ma) ? true : false
  end

  def countyzip_constraints?
    (key == :ma) ? true : false
  end

  def sites=(site_params)
    site_params.each do |site_hash|
      sites.build(site_hash)
    end
  end

  def self.find_by_key(key)
    where(key: key).first
  end
end