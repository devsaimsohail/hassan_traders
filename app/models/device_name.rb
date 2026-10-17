module DeviceName
  def self.from(user_agent)
    ua = user_agent.to_s
    case ua
    when /iPhone|iPad/ then "iPhone"
    when /Android/ then "Android"
    when /Windows/ then "Windows PC"
    when /Macintosh|Mac OS X/ then "Mac"
    when /Linux/ then "Linux PC"
    else "Browser"
    end
  end
end
