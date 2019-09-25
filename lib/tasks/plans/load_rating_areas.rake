#rake load_rate_reference:run_all_rating_areas

namespace :load_rate_reference do

  task :run_all_rating_areas => :environment do
    include ::SettingsHelper

    files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls/dc/xls_templates/rating_areas", "**", "*.xlsx"))

    puts "*"*80 unless Rails.env.test?

    if offerings_constrained_to_rating_areas
      files.each do |file|
        puts "processing file #{file}" unless Rails.env.test?
        Rake::Task['load_rate_reference:update_rating_areas'].invoke(file)
        Rake::Task['load_rate_reference:update_rating_areas'].reenable
        puts "created #{::Locations::RatingArea.all.size} rating areas in new model for all years" unless Rails.env.test?
      end
    else
      Rake::Task['load_rate_reference:default_rating_area'].invoke
    end
    puts "*"*80 unless Rails.env.test?
  end

  desc "Default rating area"
  task :default_rating_area => :environment do
    include ::SettingsHelper

    year = Date.today.year
    (year..(year + 1)).each do |year|
      puts "Creating default Rating area for #{year}" unless Rails.env.test?
      ::Locations::RatingArea.find_or_create_by!(
        {active_year: year,
         exchange_provided_code: '',
         county_zip_ids: [],
         covered_states: [state_abbreviation]}
       )
    end
  end

  desc "load rating regions from xlsx file"
  task :update_rating_areas, [:file] => :environment do |t, args|
    begin
      file = args[:file]
      file_year = 2019
      xlsx = Roo::Spreadsheet.open(file)
      sheet = xlsx.sheet(0)

      @result_hash = Hash.new {|results, k| results[k] = []}

      (2..sheet.last_row).each do |i|
        @result_hash[sheet.cell(i, 4)] << {
            "county_name" => sheet.cell(i, 2),
            "zip" => sheet.cell(i, 1)
        }
      end

      @result_hash.each do |rating_area_id, locations|

        location_ids = locations.map do |loc_record|
          county_zip = ::Locations::CountyZip.where(
            {
              zip: loc_record['zip'],
              county_name: loc_record['county_name']
            }
          ).first
          county_zip._id
        end

        ra = ::Locations::RatingArea.where(
          {
            active_year: file_year,
            exchange_provided_code: rating_area_id
          }
        ).first
        if ra.present?
          ra.county_zip_ids = location_ids
          ra.save
        else
          ::Locations::RatingArea.create(
            {
              active_year: file_year,
              exchange_provided_code: rating_area_id,
              county_zip_ids: location_ids
            }
          )
        end
      end
    rescue => e
      puts e.inspect
    end
  end

  def to_boolean(value)
    return true if value == true || value =~ (/(true|t|yes|y|1)$/i)
    return false if value == false || value =~ (/(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{value}\"")
  end
end
