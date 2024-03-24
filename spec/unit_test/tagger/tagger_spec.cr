require "../../../src/tagger/tagger"

describe "Init" do
  it "hunt_tagger" do
    noir_options = default_options()
    extected_endpoints = [
      Endpoint.new("/api/me", "GET", [
        Param.new("q", "", "query"),
        Param.new("query", "", "query"),
        Param.new("filter", "", "query"),
        Param.new("X-Forwarded-For", "", "header"),
      ]),
      Endpoint.new("/api/sign_ups", "POST", [
        Param.new("url", "", "cookie"),
        Param.new("command", "", "cookie"),
        Param.new("role", "", "cookie"),
      ]),
    ]
    run_tagger(extected_endpoints, noir_options)
    extected_endpoints.each do |endpoint|
      endpoint.params.each do |param|
        case param.name
        when "query"
          param.tags.each do |tag|
            tag.name.should eq("sqli")
          end
        when "url"
          param.tags.each do |tag|
            tag.name.should eq("ssrf")
          end
        when "role"
          param.tags.each do |tag|
            tag.name.should eq("sqli")
          end
        end
      end
    end
  end
end
