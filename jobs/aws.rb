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

    # EC2 CPU Stats
    ec2_instances = dashing_aws.getEc2Instances
    ec2_instances = ec2_instances.map(){|instance|
        {
            instance_id: instance.instance_id,
            region: 'us-east-1',
            name: instance.tags['Name']
        }
    }

    ec2_cpu_series = []
    ec2_instances.each do |item|
        cpu_data = dashing_aws.getInstanceStats(item[:instance_id], item[:region], "CPUUtilization", 'AWS/EC2', :average)
        if cpu_data
            cpu_data[:name] = item[:name]
            ec2_cpu_series.push cpu_data
        end
    end

    ec2_mem_series = []
    ec2_instances.each do |item|
        mem_data = dashing_aws.getInstanceStats(item[:instance_id], item[:region], "MemoryUtilization", 'System/Linux', :average)
        if mem_data
            mem_data[:name] = item[:name]
            ec2_mem_series.push mem_data
        end
    end


    # RDS CPU Stats
    rds_instances = dashing_aws.getRdsInstances
    rds_instances = rds_instances.map(){|instance|
        {
            instance_id: instance.db_instance_id,
            region: 'us-east-1',
            name: instance.db_instance_id
        }
    }

    rds_cpu_series = []
    rds_instances.each do |item|
        cpu_data = dashing_aws.getInstanceStats(item[:instance_id], item[:region], "CPUUtilization", 'AWS/RDS', :average)
        cpu_data[:name] = item[:name]
        rds_cpu_series.push cpu_data
    end

    # If you're using the Rickshaw Graph widget: https://gist.github.com/jwalton/6614023
    send_event "ec2-aws-cpu", { series: ec2_cpu_series }
    send_event "ec2-aws-mem", { series: ec2_mem_series }
    send_event "rds-aws-cpu", { series: rds_cpu_series }

    # If you're just using the regular Dashing graph widget:
    # send_event "aws-cpu-server1", { points: cpu_series[0][:data] }
    # send_event "aws-cpu-server2", { points: cpu_series[1][:data] }
    # send_event "aws-cpu-server3", { points: cpu_series[2][:data] }

end # SCHEDULER
