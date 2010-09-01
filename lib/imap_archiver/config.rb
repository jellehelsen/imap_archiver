require "ostruct"
module ImapArchiver
  module Config
    attr_accessor :imap_server, :username, :password, :auth_mech, :base_folder, :archive_folder, :folders_to_archive
    
    # @@config_struct = ::OpenStruct.new({:imap_server => '', 
    #                                   :username => '',
    #                                   :password => ''})
    
    def self.load_config(config_file)
      begin
        load config_file
      rescue LoadError => e
        raise "Config_file not found! #{config_file} #{e}"
      end
    end
    
    def load_config(config_file)
      @@base = self
      ImapArchiver::Config.load_config(config_file)
    end
    
    def self.run
      yield self
    end
    
    def self.included(base)
      base.extend(self)
    end
    
    # def method_missing(method, *args)
    #   @@config_struct.send(method,*args)
    # end
    
    def config_valid?
      self.auth_mech ||= "CRAM-MD5"
      raise "No imap server in configuration file!" if self.imap_server.nil?
      raise "No username in configuration file!" if username.nil?
      raise "No password in configuration file!" if password.nil?
    end
    # private
    def self.method_missing(method, *args)
      @@base.send(method,*args)
    end
    
  end
end