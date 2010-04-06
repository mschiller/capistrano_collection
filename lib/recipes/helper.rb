#Capistrano::Configuration.instance(true).load do
  # set ENV[‘HOSTS’] with domain of current role
  # http://smartic.us/2008/05/06/keeping-capistrano-in-check-ensuring-roles-are-respected-in-sub-tasks/
  def with_role(role, &block)
    original, ENV['HOSTS'] = ENV['HOSTS'], find_servers(:roles =>role).map{|d| d.host}.join(",")
    begin
      yield
    ensure
      ENV['HOSTS'] = original
    end
  end
#end
