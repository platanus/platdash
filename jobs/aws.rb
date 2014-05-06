#!/usr/bin/env ruby

#jobs/aws.rb

require './lib/dashing_aws'

dashing_aws = DashingAWS.new({
    :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
    :secret_access_key => ENV['AWS_SECRECT_ACCESS_KEY'],
})

# See documentation here for cloud watch API here: https://github.com/aws/aws-sdk-ruby/blob/af638994bb7d01a8fd0f8a6d6357567968638100/lib/aws/cloud_watch/client.rb
# See documentation on various metrics and dimensions here: http://docs.aws.amazon.com/AWSEC2/2011-07-15/UserGuide/index.html?using-cloudwatch.html

# Note that Amazon charges [$0.01 per 1000 reqeuests](http://aws.amazon.com/pricing/cloudwatch/),
# so:
#
# | frequency | $/month/stat |
# |:---------:|:------------:|
# |     1m    |     $0.432   |
# |    10m    |     $0.043   |
# |     1h    |     $0.007   |
#
# In the free tier, stats are only available for 5m intervals, so querying more often than
# once every 5 minutes is kind of pointless.  You've been warned. :)
#

SCHEDULER.every '5m', :first_in => 0 do |job|
    cpu_usage = [
        {name: 'augustijn',     instance_id: "i-4b1fc765", region: 'us-east-1', namespace: 'AWS/EC2'},
        {name: 'szot',          instance_id: "i-17050370", region: 'us-east-1', namespace: 'AWS/EC2'},
        {name: 'kwan',          instance_id: "i-33fcbd62", region: 'us-east-1', namespace: 'AWS/EC2'},
        {name: 'guinness',      instance_id: "i-4d1b212a", region: 'us-east-1', namespace: 'AWS/EC2'},
        {name: 'quehambre',     instance_id: "i-c8e8a9ac", region: 'us-east-1', namespace: 'AWS/EC2'},
        {name: 'corona',        instance_id: "i-47e7fd22", region: 'us-east-1', namespace: 'AWS/EC2'},
        {name: 'db-mysql',      instance_id: "platanusdb", region: 'us-east-1', namespace: 'AWS/RDS'},
        {name: 'db-ghoster',    instance_id: "ghosterdb",  region: 'us-east-1', namespace: 'AWS/RDS'},
        {name: 'db-postgres',   instance_id: "platanuspg", region: 'us-east-1', namespace: 'AWS/RDS'},
    ]

    cpu_series = []
    cpu_usage.each do |item|
        cpu_data = dashing_aws.getInstanceStats(item[:instance_id], item[:region], "CPUUtilization", item[:namespace], :average)
        cpu_data[:name] = item[:name]
        cpu_series.push cpu_data
    end

    # If you're using the Rickshaw Graph widget: https://gist.github.com/jwalton/6614023
    send_event "aws-cpu", { series: cpu_series }

    # If you're just using the regular Dashing graph widget:
    # send_event "aws-cpu-server1", { points: cpu_series[0][:data] }
    # send_event "aws-cpu-server2", { points: cpu_series[1][:data] }
    # send_event "aws-cpu-server3", { points: cpu_series[2][:data] }

end # SCHEDULER
