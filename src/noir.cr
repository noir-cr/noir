require "option_parser"
require "colorize"
require "./models/noir.cr"
require "./banner.cr"
require "./options.cr"
require "./techs/techs.cr"

module Noir
  VERSION = "0.13.0"
end

noir_options = default_options()
banner()

OptionParser.parse do |parser|
  parser.banner = "Usage: noir <flags>"
  parser.separator "  Basic:".colorize(:blue)
  parser.on "-b PATH", "--base-path ./app", "(Required) Set base path" { |var| noir_options[:base] = var }
  parser.on "-u URL", "--url http://..", "Set base url for endpoints" { |var| noir_options[:url] = var }

  parser.separator "\n  Output:".colorize(:blue)

  parser.on "-f FORMAT", "--format json", "Set output format\n  * plain yaml json jsonl markdown-table\n  * curl httpie oas2 oas3\n  * only-url only-param only-header only-cookie" { |var| noir_options[:format] = var }
  parser.on "-o PATH", "--output out.txt", "Write result to file" { |var| noir_options[:output] = var }
  parser.on "--set-pvalue VALUE", "Specifies the value of the identified parameter" { |var| noir_options[:set_pvalue] = var }
  parser.on "--include-path", "Include file path in the plain result" do
    noir_options[:include_path] = "yes"
  end
  parser.on "--no-color", "Disable color output" do
    noir_options[:color] = "no"
  end
  parser.on "--no-log", "Displaying only the results" do
    noir_options[:nolog] = "yes"
  end

  parser.separator "\n  Tagger:".colorize(:blue)
  parser.on "--tagger", "Use tagger" { |_| noir_options[:tagger] = "yes" }

  parser.separator "\n  Deliver:".colorize(:blue)
  parser.on "--send-req", "Send results to a web request" { |_| noir_options[:send_req] = "yes" }
  parser.on "--send-proxy http://proxy..", "Send results to a web request via an HTTP proxy" { |var| noir_options[:send_proxy] = var }
  parser.on "--send-es http://es..", "Send results to Elasticsearch" { |var| noir_options[:send_es] = var }
  parser.on "--with-headers X-Header:Value", "Add custom headers to be included in the delivery" do |var|
    noir_options[:send_with_headers] += "#{var}::NOIR::HEADERS::SPLIT::"
  end
  parser.on "--use-matchers string", "Send URLs that match specific conditions to the Deliver" do |var|
    noir_options[:use_matchers] += "#{var}::NOIR::MATCHER::SPLIT::"
  end
  parser.on "--use-filters string", "Exclude URLs that match specified conditions and send the rest to Deliver" do |var|
    noir_options[:use_filters] += "#{var}::NOIR::FILTER::SPLIT::"
  end

  parser.separator "\n  Technologies:".colorize(:blue)
  parser.on "-t TECHS", "--techs rails,php", "Specify the technologies to use" { |var| noir_options[:techs] = var }
  parser.on "--exclude-techs rails,php", "Specify the technologies to be excluded" { |var| noir_options[:exclude_techs] = var }
  parser.on "--list-techs", "Show all technologies" do
    puts "Available technologies:"
    techs = NoirTechs.get_techs
    techs.each do |tech, value|
      puts "  #{tech.to_s.colorize(:green)}"
      value.each do |k, v|
        puts "    #{k.to_s.colorize(:blue)}: #{v}"
      end
    end
    exit
  end

  parser.separator "\n  Config:".colorize(:blue)
  parser.on "--config-file ./config.yaml", "Specify the path to a configuration file in YAML format" { |var| noir_options[:config_file] = var }
  parser.on "--concurrency 100", "Set concurrency" { |var| noir_options[:concurrency] = var }

  parser.separator "\n  Others:".colorize(:blue)
  parser.on "-d", "--debug", "Show debug messages" do
    noir_options[:debug] = "yes"
  end
  parser.on "-v", "--version", "Show version" do
    puts Noir::VERSION
    exit
  end
  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end
  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
  parser.missing_option do |flag|
    STDERR.puts "ERROR: #{flag} is missing an argument."
    exit(1)
  end
end

if noir_options[:base] == ""
  STDERR.puts "ERROR: Base path is required."
  STDERR.puts "Please use -b or --base-path to set base path."
  STDERR.puts "If you need help, use -h or --help."
  exit(1)
end

app = NoirRunner.new noir_options
app.logger.debug("Start Debug mode")
app.logger.debug("Noir version: #{Noir::VERSION}")
app.logger.debug("Noir options from arguments:")
noir_options.each do |k, v|
  app.logger.debug_sub("#{k}: #{v}")
end

app.logger.debug "Initialized Options:"
app.options.each do |k, v|
  app.logger.debug_sub "#{k}: #{v}"
end

app.logger.system "Detecting technologies to base directory."
app.detect

if app.techs.size == 0
  app.logger.info "No technologies detected."
  if app.options[:url] != ""
    app.logger.system "Start file-based analysis as the -u flag has been used."
  else
    exit(0)
  end
else
  app.logger.info "Detected #{app.techs.size} technologies."
  app.techs.each do |tech|
    app.logger.info_sub "#{tech}"
  end
  app.logger.system "Start code analysis based on the detected technology."
end

app.analyze
app.logger.info "Finally identified #{app.endpoints.size} endpoints."

app.logger.system "Generating Report."
app.report
