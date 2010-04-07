#Capistrano::Configuration.instance(true).load do
  namespace :deploy do
    namespace :cron do
      desc <<-DESC
      Update the crontab file
      This will update your crontab file, leaving any existing entries unharmed.
      When using the update-crontab option, Whenever will only update the entries
      in your crontab file related to the current schedule.rb file. You can replace
      the #{application} with any identifying string you�d like. You can have any
      number of apps deploy to the same crontab file peacefully given they each use
      a different identifier.
      DESC
      task :update, :roles => :app do
        vars = "action=add&project=#{application}&environment=#{fetch(:rails_env, "production")}&cron_log=#{current_path}/log/cron_log.log&error_log=#{current_path}/log/cron_error_log.log"
        run "cd #{current_path} && whenever --update-crontab '#{application}' --load-file '#{fetch(:cron_config_file, "#{current_path}/config/schedule.rb")}' --set '#{vars}' && crontab -l"
        # --write-crontab => overwrites your crontab file each time you deploy,
        # --load-file and --user
      end

      desc <<-DESC
      Delete the crontab entry for current project
      DESC
      task :delete_entry, :roles => :app do
        vars = "action=delete&project=#{application}"
        run "cd #{current_path} && whenever --update-crontab '#{application}' --load-file '#{fetch(:cron_config_file, "#{current_path}/config/schedule.rb")}' --set '#{vars}' && crontab -l"
      end

      desc <<-DESC
      Get current cron configuration
      DESC
      task :get_config_info, :roles => :app do
        run "crontab -l"
      end
    end
  end
#end
