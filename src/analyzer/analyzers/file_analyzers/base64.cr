require "base64"
require "../../../models/analyzer"
require "../../../models/endpoint"

FileAnalyzer.add_hook(->(path : String, url : String) : Array(Endpoint) {
  results = [] of Endpoint

  begin
    File.open(path, "r", encoding: "utf-8", invalid: :skip) do |file|
      file.each_line.with_index do |line, index|
        # Check base64 encoded strings
        base64_match = line.match(/([A-Za-z0-9+\/]{20,}={0,2})/)
        if base64_match
          decoded = Base64.decode_string(base64_match[1])
          url_match = decoded.match(/(https?:\/\/[^\s"]+)/)
          if url_match
            parsed_url = URI.parse(url_match[1])
            if parsed_url.to_s.includes? url
              details = Details.new(PathInfo.new(path, index + 1))
              results << Endpoint.new(parsed_url.path, "GET", details)
            end
          end
        end
      end
    end
  rescue
  end

  results
})
