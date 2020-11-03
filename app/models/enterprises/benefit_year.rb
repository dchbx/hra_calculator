class Enterprises::BenefitYear
  include Mongoid::Document
  include Mongoid::Timestamps

  field :expected_contribution, type: Float # .0986 in 2020
  field :calendar_year, type: Integer
  field :description, type: String
  field :is_active, type: Boolean, default: false

  # has_many   :products,      class_name: 'Products::Product'
  # has_many   :rating_areas,  class_name: 'Locations::RatingArea'
  # has_many   :service_areas, class_name: 'Locations::ServiceArea'

  belongs_to :enterprise, class_name: 'Enterprises::Enterprise'

  validates :expected_contribution, numericality: { greater_than: 0, less_than: 1 }

  def make_inactive
    update(is_active: false)
  end

  def make_active
    update(is_active: true)
  end
end
