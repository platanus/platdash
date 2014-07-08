SCHEDULER.every '5m', :first_in => 1 do |job|

  changes = []

  fetcher = SpreadsheetFetcher.new
  spreadsheet_id = GeneralKeyValue.instance.get(:changes_restos_spreadsheet)

  w = fetcher.fetch(spreadsheet_id).worksheets[0]

  for row in 2..w.num_rows
    if w[row,2]
      changes.push(
        {
          restaurant: w[row,1],
          responsible: w[row,2],
          topic: w[row,3]
        })
    end
  end
  # puts restaurants.inspect!
  send_event('changes_restos', {changes: changes[0..2]})
end
