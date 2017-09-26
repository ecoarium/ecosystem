
class Chef
  class Application
    class Solo
      def run_application
        for_ezra if Chef::Config[:ez]
        if !Chef::Config[:client_fork] || Chef::Config[:once]
          # Run immediately without interval sleep or splay
          begin
            run_chef_client(Chef::Config[:specific_recipes])
          rescue SystemExit
            raise
          rescue Exception => e
            Chef::Application.fatal!("#{e.class}: #{e.message}", 1)
          end
        else
          interval_run_chef_client
        end
      end
    end
  end
end