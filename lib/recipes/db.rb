#Capistrano::Configuration.instance(true).load do
  namespace :db do
    namespace :mysql do
      desc <<-DESC
        Restore of current database
        cap db:mysql:restore N(ame of db)=xxx (database)E(xists)=true
      DESC
      task :restore, :roles => :db do
        rake = fetch(:rake, "rake")
        password = fetch(:mysql_password, nil)
        password = Capistrano::CLI.password_prompt("MySQL password for #{user}: ") unless password
        env_n = "N=#{ENV['N'] || fetch(:mysql_database, nil)}" || ""
        env_u = "U=#{fetch(:mysql_user, fetch(:user, ''))}" || ''
        env_p = "P=#{password}" || ""
        env_e = "E=#{ENV['E']}" if ENV['E']
        env = "RAILS_ENV=#{fetch(:rails_env, 'test')}"
        puts "[MYSQL] restore database #{env_n}"
        run "cd #{ENV['RESTORE_FROM'] || current_path} && #{rake} #{env_n} #{env_u} #{env_p} #{env_e} #{env} Q=false  db:restore"
      end

      task :restore_from_cache, :roles => :db do
        ENV['RESTORE_FROM'] = File.join(shared_path, fetch(:repository_cache, "cached-copy"))
        db.mysql.restore
      end

      desc <<-DESC
        Create a new MYSQL Database
        cap db:mysql:create N(ame of db)=xxx
      DESC
      task :create, :roles => :db, :except => { :no_release => true } do
        on_rollback {}
        password = fetch(:mysql_password, nil)
        password = Capistrano::CLI.password_prompt("MySQL password for #{user}: ") unless password
        database = ENV['N'] || fetch(:mysql_database, nil)
        sql = "CREATE DATABASE #{database};"
        sql += "GRANT ALL PRIVILEGES ON #{database}.* TO #{user}@localhost IDENTIFIED BY '#{password}';"
        puts "[MYSQL] create database #{database}"
        sudo "mysql -u #{fetch(:mysql_user, fetch(:user, ''))} -p'#{password}' --execute=\"#{sql}\" || true; echo return_code: $?"
      end

      desc <<-DESC
        Destroy a new MYSQL Database
        cap db:mysql:destroy N(ame of db)=xxx
      DESC
      task :destroy, :roles => :db, :except => { :no_release => true } do
        on_rollback {}
        password = fetch(:mysql_password, nil)
        password = Capistrano::CLI.password_prompt("MySQL password for #{user}: ") unless password
        database = ENV['N'] || fetch(:mysql_database, nil)
        sql = "DROP DATABASE #{database};"
        puts "[MYSQL] destroy database #{database}"
        sudo "mysql -u #{fetch(:mysql_user, fetch(:user, ''))} -p'#{password}' --execute=\"#{sql}\""
      end
    end

    task :schema_update_for_plugin_migration, :roles => :db, :except => { :no_release => true } do
      on_rollback {}
      # two times because of problems with
      run "cd #{current_path} && RAILS_ENV=#{fetch(:rails_env, 'production')} rake rails:update:schema_migrations || true; echo return_code: $?"
      run "cd #{current_path} && RAILS_ENV=#{fetch(:rails_env, 'production')} rake rails:update:schema_migrations"
    end
  end
#end
