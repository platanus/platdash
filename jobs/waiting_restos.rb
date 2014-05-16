SCHEDULER.every '1m', :first_in => 1 do |job|

  restaurants = []

  fetcher = SpreadsheetFetcher.new
  spreadsheet_id = GeneralKeyValue.instance.get(:waiting_restos_spreadsheet)
  w = fetcher.fetch(spreadsheet_id).worksheets[0]

  for row in 2..w.num_rows
    if w[row,2]
      restaurants.push(
        {
          name: w[row,1],
          date: w[row,2],
          days: (Date.today - Date.parse(w[row,2])).round
        })
      restaurants.last[:face] = (restaurants.last[:days].to_i > 5) ? 'fa fa-frown-o' : 'fa fa-cutlery'
    end
  end

  # puts restaurants.inspect
  send_event('waiting_restos', {items: restaurants})
end
