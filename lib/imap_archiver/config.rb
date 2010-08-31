require "ostruct"
module ImapArchiver
  module Config
    @@config_struct = ::OpenStruct.new({:imap_server => '', 
                                      :username => '',
                                      :password => ''})
    
    def self.load_config(config_file)
      begin
        require config_file
      rescue LoadError
        raise "Config_file not found!"
      end
    end
    
    def self.run
      yield self
    end
    
    private
    def self.method_missing(method, *args)
      @@config_struct.send(method,*args)
    end
    
  end
end