module Validations
  class BenefitYearCreateContract < ::Dry::Validation::Contract
    params do
      required(:expected_contribution).filled(:float)
      required(:calendar_year).filled(:integer)
    end

    rule(:calendar_year) do
      benefit_year = ::Enterprises::BenefitYear.all.where(calendar_year: value)
      puts "Benefit Year #{benefit_year}"
      key.failure("is unique for BenefitYear") if benefit_year.present?
    end
  end
end
