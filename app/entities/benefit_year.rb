class BenefitYear < Dry::Struct
  transform_keys(&:to_sym)

  attribute :expected_contribution, Types::Float # .0986 in 2020
  attribute :calendar_year, Types::Integer
end