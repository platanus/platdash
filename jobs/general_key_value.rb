require './lib/general_key_value'

SCHEDULER.every '1m', :first_in => 1 do |job|

  GeneralKeyValue.instance.update
end