module ImapArchiver
  class Archiver
    attr_accessor :mailserver, :username, :password, :connection, :auth_mech, :base_folder
    def initialize(mailserver,username,password,auth_mech="CRAM-MD5")
      self.mailserver = mailserver
      self.username   = username
      self.password   = password
      self.auth_mech  = auth_mech
    end
    
    def connect
      self.reconnect
      @msg_count = 0
    end
    
    def reconnect
      self.connection = Net::IMAP.new(mailserver)
      self.connection.authenticate(auth_mech,username,password)
    end
    
    def folder_list
      connection.list(base_folder,"*")
    end
    
    def archive_all    
      folder_list.each do |folder|        
        since_date = Date.today.months_ago(3).beginning_of_month 
        before_date= Date.today.months_ago(3).end_of_month 
        archive_folder_between_dates(folder.name,since_date,before_date) if folder.name =~ /^Public Folders\/Team\//
      end
    end
    
    def archive_folder_between_dates(folder, since_date, before_date)
      tmp_folder = Pathname.new(folder).relative_path_from(Pathname.new('Public Folders')).to_s
      archive_folder = "Public Folders/Archief/#{tmp_folder}/#{since_date.strftime("%b %Y")}"
      puts archive_folder
      conditions = ["SINCE", since_date.strftime("%d-%b-%Y"), "BEFORE", before_date.strftime("%d-%b-%Y"), "SEEN", "NOT", "FLAGGED"]
      retry_count = 0
      begin
        connection.select(folder)
        msgs_to_archive = connection.search(conditions)
        if msgs_to_archive.size > 0
          if connection.list("",archive_folder).nil?
            connection.create(archive_folder)
            puts "#{archive_folder} created"
          end
          connection.copy(msgs_to_archive, archive_folder)
          connection.store(msgs_to_archive, "+FLAGS",[:Deleted])
          @msg_count += msgs_to_archive.size
          connection.expunge
        end
        if connection.search(["BEFORE", since_date.strftime("%d-%b-%Y"), "SEEN", "NOT", "FLAGGED"]).size > 0
          archive_folder_between_dates(folder,since_date - 1.month, since_date)
        end
      rescue IOError => e
        retry_count += 1

        if retry_count < 3
          reconnect
          retry
        else
          puts "Error archiving #{folder} to #{archive_folder}: #{e}"
          puts e.backtrace
        end
      rescue Exception => e
        retry_count += 1
        if retry_count < 3
          retry
        else
          puts "Error archiving #{folder} to #{archive_folder}: #{e}"
          puts e.backtrace
        end
      end
    end
    
  end
end