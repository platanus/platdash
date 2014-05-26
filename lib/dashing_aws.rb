#lib/dashing_aws.rb

require 'aws-sdk'
require 'time'

class DashingAWS

    def initialize(options)
        @access_key_id = options[:access_key_id]
        @secret_access_key = options[:secret_access_key]
        @cwClientCache = {}
    end

    def getEc2Instances()
        # Get an API client instance
        ec2 = @ec2
        if not ec2
            ec2 = @ec2 = AWS::EC2.new({
                access_key_id: @access_key_id,
                secret_access_key: @secret_access_key
            })
        end

        ec2.instances.tagged("Name")
    end

    def getRdsInstances()
        # Get an API client instance
        rds = @rds
        if not rds
            rds = @rds = AWS::RDS.new({
                access_key_id: @access_key_id,
                secret_access_key: @secret_access_key
            })
        end

        rds.instances
    end

    # Get statistics for an instance
    #
    # * `instance_id` is the instance to get data about.
    # * `region` is the name of the region the instance is from (e.g. 'us-east-1'.)  See
    #   [monitoring URIs](http://docs.aws.amazon.com/general/latest/gr/rande.html#cw_region).
    # * `metric_name` is the metric to get.  See
    #   [the list of build in metrics](http://docs.aws.amazon.com/AWSEC2/2011-07-15/UserGuide/index.html?using-cloudwatch.html).
    # * `type` is `:average` or `:maximum`.
    # * `options` are [:start_time, :end_time, :period, :dimensions, :min_y] as per
    #   `get_metric_statistics()`, although all are optional.  Also:
    #   * `:duration` - If supplied, and no start_time or end_time are supplied, then start_time
    #     and end_time will be computed based on this value in seconds.  Defaults to 6 hours.
    def getInstanceStats(instance_id, region, metric_name, namespace='AWS/EC2', type=:average, options={})
        if type == :average
            statName = "Average"
        elsif type == :maximum
            statName = "Maxmimum"
        end
        statKey = type

        # Get an API client instance
        cw = @cwClientCache[region]
        if not cw
            cw = @cwClientCache[region] = AWS::CloudWatch::Client.new({
                server: "https://monitoring.#{region}.amazonaws.com",
                access_key_id: @access_key_id,
                secret_access_key: @secret_access_key
            })
        end

        # Build a default set of options to pass to get_metric_statistics
        instanceIdName = (namespace=='AWS/RDS') ? "DBInstanceIdentifier" : "InstanceId"
        duration = (options[:duration] or (60*60*6)) # Six hours
        start_time = (options[:start_time] or (Time.now - duration))
        end_time = (options[:end_time] or (Time.now))
        dimensions = (options[:dimensions] or [{name: instanceIdName, value: instance_id}])
        get_metric_statistics_options = {
            namespace: namespace,
            metric_name: metric_name,
            statistics: [statName],
            start_time: start_time.utc.iso8601,
            end_time: end_time.utc.iso8601,
            period: (options[:period] or (60 * 5)), # Default to 5 min stats
            dimensions: dimensions
        }

        # Go get stats
        result = cw.get_metric_statistics(get_metric_statistics_options)

        if ((not result[:datapoints]) or (result[:datapoints].length == 0))
            # TODO: What kind of errors can I get back?
            puts "\e[33mWarning: Got back no data for instanceId: #{region}:#{instance_id} for metric #{metric_name}\e[0m"
            answer = nil
        else
            # Turn the result into a Rickshaw-style series
            data = []

            result[:datapoints].each do |datapoint|
                point = {
                    x: (datapoint[:timestamp].to_i), # time in seconds since epoch
                    y: datapoint[statKey]
                }
                data.push point
            end
            data.sort! { |a,b| a[:x] <=> b[:x] }

            answer = {
                name: "#{metric_name} for #{instance_id}",
                data: data
            }

            if options[:min_y] and not answer[:data].any?(){|d| d[:y] > options[:min_y].to_f}
                puts "\e[33mWarning: Skip data for instanceId: #{region}:#{instance_id} for metric #{metric_name}\e[0m"
                answer[:data] = nil
            end
        end

        return answer
    end

end
