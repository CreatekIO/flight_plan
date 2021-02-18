desc 'Fetch holidays for `config/business_time.yml`'
task fetch_holidays: :environment do
  response = Faraday.get('https://www.gov.uk/bank-holidays/england-and-wales.ics')

  raise response.inspect unless response.success?

  marker = 'BEGIN:VEVENT'

  # Bare-bones iCal parsing, just enough for our needs
  holidays = response.body
    .split(/\r?\n/)
    .slice_before(marker)
    .select { |props| props.first == marker }
    .map { |props| props.map { |prop| prop.split(/:|;VALUE=DATE:/) }.to_h }

  holidays.each do |holiday|
    date = Date.parse(holiday['DTSTART'])
    name = holiday['SUMMARY']

    puts "- '#{date.strftime('%d')} #{date.strftime('%B').ljust(9)} #{date.year}' # #{name}"
  end
end
