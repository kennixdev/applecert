require 'openssl'
require 'plist'
require 'colorize'
require 'nokogiri'

class PROV_TYPE
  DEV='Develop'
  ADHOC='AdHoc'
  APPSTORE='AppStore'
  INHOUSE='InHouse'
end

module AppleCert
  class Provisioning
    FOLDER_PATH = ENV['HOME']+ "/Library/MobileDevice/Provisioning Profiles"

    def list
      result = self.getAllProfileInfo(FOLDER_PATH)
      self.printlist(result)
    end


    def get_profile_info(provisioning_profile_path)
      profile_contents = File.open(provisioning_profile_path).read
      profile_contents = profile_contents.slice(profile_contents.index('<?'), profile_contents.length)
      info = {}
      keys = ['UUID','application-identifier','Name','CreationDate','aps-environment','ExpirationDate']
      doc = Nokogiri.XML(profile_contents)
      # puts "#{doc}"
      keys.each do |key|
        value = doc.xpath("\/\/key[text()=\"#{key}\"]")[0]
        if value.to_s.length>0
          value = value.next_element.text
          info[key] = value
        end
      end

      keys = ['ProvisionedDevices','DeveloperCertificates']
      keys.each do |key|
        node = doc.xpath("\/\/key[text()=\"#{key}\"]")[0]
        arr = Array.new()
        if node.to_s.length>0
          node.next_element.children.each do  |nodes|
            if nodes.text.strip.to_s.length > 0
              arr.push(nodes.text.strip)
            end
          end
        end
        info[key] = arr
      end

      isEnterprise = false
      key = 'ProvisionsAllDevices'
      if node = doc.xpath("\/\/key[text()=\"#{key}\"]")[0]
        if node.to_s.length>0
          if node.next_element.name.downcase == 'true'
            isEnterprise = true
          end
        end
      end

      certlist = Array.new()
      if !info['DeveloperCertificates'].nil?
        values = info['DeveloperCertificates']
        index = 0
        values.each do |item|
          decode_base64_content = Base64.decode64(item)
          cert = OpenSSL::X509::Certificate.new(decode_base64_content)
          certlist.push(cert.subject.to_s)
          if index == 0
            if cert.subject.to_s.match('/CN=iPhone Developer')
              info[:cert_type] = PROV_TYPE::DEV
            elsif !info['ProvisionedDevices'].nil? && info['ProvisionedDevices'].length > 0
              info[:cert_type] = PROV_TYPE::ADHOC
            elsif isEnterprise
              info[:cert_type] = PROV_TYPE::INHOUSE
            else
              info[:cert_type] = PROV_TYPE::APPSTORE
            end
            regex = /\/O=(.*)\/C/
            name = cert.subject.to_s.scan(regex)
            if name.length > 0 && name[0].length > 0
              info[:team_name] = name.first.first
            else
              info[:team_name] = ""
            end
          end
          index += 1
        end
        info['DeveloperCertificates'] = certlist
      end
      return info
    end

    def getAllProfileInfo(path)
      result = {}
      list = Dir["#{path}/*"]
      list.each do |profilePath|
        obj = get_profile_info(profilePath)
        app_id = obj['application-identifier']
        cert_type_dict = {}
        if !result[app_id].nil?
          cert_type_dict = result[app_id]
        end
        arr = Array.new()
        cert_type = obj[:cert_type]
        if !cert_type_dict[cert_type].nil?
          arr = cert_type_dict[cert_type]
        end
        arr.push(obj)
        cert_type_dict[cert_type] = arr
        result[app_id] = cert_type_dict
      end
      return result
    end

    def showInfo(uuid)
      profilePath = "#{FOLDER_PATH}/#{uuid.downcase}.mobileprovision"
      if File.exist? profilePath
        obj = get_profile_info(profilePath)
        self.printAProvision(obj)
      else
        puts "provisioning for #{uuid} not exist".red
        abort("")
      end
    end

    def removeExpired()
      expiredlist = Array.new()
      result = getAllProfileInfo(FOLDER_PATH)
      result.keys.sort.each.each do |app_id|
        cert_type_dict = result[app_id]
        cert_type_dict.each do |type, arr|
          arr.each do |info|
            dateStr = info['ExpirationDate']
            if DateTime.now > DateTime.parse(dateStr)
              expiredlist.push(info)
            end
          end
        end
      end
      expiredlist.each do |info|
        puts "#{info["ExpirationDate"]}\t#{info["application-identifier"]}\t#{info[:cert_type]}\t#{info["UUID"]}\t#{info["Name"]}\t#{info[:team_name]}"
        self.removefile(info["UUID"])
      end
    end

    def removefile(uuid)
      profilePath = "#{FOLDER_PATH}/#{uuid.downcase}.mobileprovision"
      if File.exist? profilePath
        File.delete(profilePath)
      else
        puts "provisioning for #{uuid} not exist".red
        abort("")
      end
    end

    def printlist(result)
      result.keys.sort.each.each do |app_id|
        cert_type_dict = result[app_id]
        puts "=========== #{app_id} ===========".green
        cert_type_dict.each do |type, arr|
          puts "#{type} :: #{arr[0][:team_name]}"
          arr = arr.sort {|a,b| a["ExpirationDate"] <=> b["ExpirationDate"]}
          arr.each do |info|
            if info["aps-environment"].to_s.length>0
              has_push = "[HAS_PUSH]"
            end
            puts "    #{info["ExpirationDate"]}\t #{info["UUID"]}\t#{info["Name"]} #{has_push}"
          end
        end
        puts ""
      end
    end

    def printAProvision(info)
      puts "=====================================".green
      puts "UUID: #{info["UUID"]}"
      puts "AppId: #{info['application-identifier']}"
      puts "Provisioning Name: #{info['Name']}"
      puts "Team Name: #{info[:team_name]}"
      puts "Cert Type: #{info[:cert_type]}"
      puts "ExpirationDate: #{info['ExpirationDate']}"
      has_push = false
      if info["aps-environment"].to_s.length>0
        has_push = true
      end
      puts "Has Push: #{has_push}"

      puts "DeveloperCertificates: "
      info['DeveloperCertificates'].each do |item|
        puts "  #{item}"
      end
      if !info['ProvisionedDevices'].nil?
        puts "ProvisionedDevices: "
        info['ProvisionedDevices'].each do |item|
          puts "  #{item}"
        end
      end

    end
  end
end


# man = AppleCert::Provisioning.new()
# man.li
# man.removeExpired
# uuid = '69bb2234-82a1-44b4-bee2-f78c56e007f9'
# uuid = '4951f5cb-820b-44af-b766-67a042fbf386'
# uuid = '4ee2632b-2048-497d-978e-f62d1356436f'
# man.showInfo(uuid)