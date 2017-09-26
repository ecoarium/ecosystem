require 'logging-helper'
require 'lps'
require 'cucumber/runtime'
require 'cucumber/cli/main'
require 'securerandom'
require 'tempfile'
require 'pp'

module Performance
  class LoadGenerator
    class << self
      def run_it(rate, duration, ramp_time, max_runners, scenarios)
        new.run_it(rate, duration, ramp_time, max_runners, scenarios)
      end
    end

    include LoggingHelper::LogToTerminal

    attr_reader :ip, :host

    def initialize
      @ip = IPSocket.getaddress(Socket.gethostname)
      @host = Socket.gethostname
    end

    def run_it(rate, duration, ramp_time, max_runners, scenarios)
      start_time = Time.now
      stop_time = start_time + duration * 60

      count = 0
      puts "
###################################### HOST GENERATOR #{ip} STARTING ######################################

  rate:       #{rate}
  duration:   #{duration}
  ramp_time:  #{ramp_time}
  scenarios:  #{scenarios.inspect}

"
      cmd = Regexp.escape("#{ENV['_']} #{ARGV.join(' ')}")

      LPS.while { Time.now < stop_time }.loop do |lps|

        runners = `ps ux | grep '#{cmd}' | wc -l`.strip.to_i
        if runners > max_runners
          puts "runners max'd out at #{runners}"
          sleep 1
          next
        end

        count += 1
        senario_instance_id = SecureRandom.urlsafe_base64(9)
        scenario = scenarios.sample
        fork_start_time = Time.now

        pid = fork do
          ::Cucumber::Cli::Main.class_eval do
            def execute!(existing_runtime = nil)
              trap_interrupt

              runtime = if existing_runtime
                existing_runtime.configure(configuration)
                existing_runtime
              else
                ::Cucumber::Runtime.new(configuration)
              end

              runtime.run!
              if ::Cucumber.wants_to_quit
                exit_unable_to_finish
              else
                if runtime.failure?
                  exit_tests_failed
                else
                  exit_ok
                end
              end
            end
          end

          # out, err = Tempfile.new("out"), Tempfile.new("err")
          # $stdout.reopen(out)
          # $stderr.reopen(err)

          ENV['SCENARIO'] = scenario
          ENV['IP'] = ip
          ENV['HOST'] = host
          ENV['RATE'] = lps.freq.to_s
          ENV['RUNNERS'] = runners.to_s
          ENV['SENARIO_INSTANCE_ID'] = senario_instance_id
          ENV['RAMPED'] = (Time.now > start_time + (ramp_time * 60)).to_s

          cucumber_opts = [
            "#{$WORKSPACE_SETTINGS[:paths][:project_paths_acceptance_tests]}/features/#{scenario}",
            "-r",
            "#{$WORKSPACE_SETTINGS[:paths][:project_paths_performance_tests]}/lib/performance.rb",
            "-r",
            "#{$WORKSPACE_SETTINGS[:paths][:project_paths_acceptance_tests]}/features/steps"
          ]
          cuke = Cucumber::Cli::Main.new(cucumber_opts)
          success = cuke.execute!
          #update_point senario_instance_id, success, out.read, err.read

          exit
        end
        begin
          Process.detach(pid) 
        rescue => e
          error "failed to detach #{pid}:\n\t#{e.message}"
        end
        lps.freq = [rate, (rate * (Time.now-start_time)/(ramp_time*60)) + 0.1].min

        puts "
  ((((((((((((( HOST GENERATOR #{ip} )))))))))))))))))

      fork duration:      #{Time.now - fork_start_time} secs
      current rate:       #{lps.freq.to_s}
      iteration count:    #{count}
      runners:            #{runners.to_s}
      time:               #{Time.now}

  ((((((((((((( HOST GENERATOR #{ip} )))))))))))))))))
"
      end

      puts "

###################################### HOST GENERATOR #{ip} FINISHED ######################################

"
    end
    
    def update_point scenario_id, success, out, err
      @client = Elasticsearch::Client.new log: false, host: ENV['Perf_Monitor_IP'] || '10.4.4.200'
      esData = @client.search index: 'perf', body: { size: 10000000, 
      query: { must: { term: { scenario_id: scenario_id } } } }
      esData['hits']['hits'].each do |i| 
        @client.update index: 'perf', type: 'event', id: i['_id'], body: { doc: { success: success, out: out, err: err } }
      end
    rescue
      nil
    end

  end
end