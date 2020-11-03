module Transactions
  class CreateBenefitYear
    include Dry::Transaction

    step :fetch
    step :validate
    step :persist

    private

    def fetch(input, enterprise_id:)
      puts "Input #{input}"
      @enterprise = ::Enterprises::Enterprise.find(input['enterprise_id'])

      if @enterprise.blank?
        Failure({errors: ["Unable to find enterprise record with id: #{enterprise_id}"]})
      else
        Success(input)
      end
    end

    def validate(input)
      output = ::Validations::BenefitYearCreateContract.new.call(input)

      if output.failure?
        result = output.to_h
        result[:errors] = []
        output.errors.to_h.each_pair do |keyy, val|
          result[:errors] << "#{keyy.to_s} #{val.first}"
        end
        Failure(result) # result is a hash.
      else
        Success(output)
      end
    end

    def persist(input)
      benefit_year = ::Enterprises::BenefitYear.new(input.to_h)
      benefit_year.enterprise = @enterprise

      if benefit_year.save
        Success(benefit_year)
      else
        Failure({errors: benefit_year.errors.full_messages})
      end
    end
  end
end
