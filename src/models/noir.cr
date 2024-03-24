require "../detector/detector.cr"
require "../analyzer/analyzer.cr"
require "../tagger/tagger.cr"
require "../deliver/*"
require "../output_builder/*"
require "./endpoint.cr"
require "./logger.cr"
require "../utils/string_extension.cr"
require "json"

class NoirRunner
  @options : Hash(Symbol, String)
  @techs : Array(String)
  @endpoints : Array(Endpoint)
  @logger : NoirLogger
  @send_proxy : String
  @send_req : String
  @send_es : String
  @is_debug : Bool
  @is_color : Bool
  @is_log : Bool
  @concurrency : Int32
  @config_file : String

  macro define_getter_methods(names)
    {% for name, index in names %}
      def {{name.id}}
        @{{name.id}}
      end
    {% end %}
  end

  define_getter_methods [options, techs, endpoints, logger]

  def initialize(options)
    @options = options
    @config_file = @options[:config_file]

    if @config_file != ""
      config = YAML.parse(File.read(@config_file))
      @options.each do |key, _|
        string_key = key.to_s
        begin
          if config[string_key] != "" && string_key != "base"
            @options[key] = "yes" if config[string_key] == true
            @options[key] = "no" if config[string_key] == false

            @options[key] = config[string_key].as_s
          end
        rescue
        end
      end
    end

    @techs = [] of String
    @endpoints = [] of Endpoint
    @send_proxy = @options[:send_proxy]
    @send_req = @options[:send_req]
    @send_es = @options[:send_es]
    @is_debug = str_to_bool(@options[:debug])
    @is_color = str_to_bool(@options[:color])
    @is_log = str_to_bool(@options[:nolog])
    @concurrency = @options[:concurrency].to_i

    @logger = NoirLogger.new @is_debug, @is_color, @is_log

    if @options[:techs].size > 0
      techs_tmp = @options[:techs].split(",")
      @logger.info "Setting #{techs_tmp.size} techs from command line."
      techs_tmp.each do |tech|
        @techs << NoirTechs.similar_to_tech(tech)
        @logger.debug "Added #{tech} to techs."
      end
    end
  end

  def run
    puts @techs
  end

  def detect
    detected_techs = detect_techs options[:base], options, @logger
    @techs += detected_techs
    if @is_debug
      @logger.debug("CodeLocator Table:")
      locator = CodeLocator.instance
      locator.show_table
    end
  end

  def analyze
    @endpoints = analysis_endpoints options, @techs, @logger
    optimize_endpoints
    combine_url_and_endpoints
    if @options[:tagger] == "yes"
      run_tagger @endpoints, @options
    end
    deliver
  end

  def optimize_endpoints
    @logger.system "Optimizing endpoints."
    final = [] of Endpoint

    @endpoints.each do |endpoint|
      tiny_tmp = endpoint
      if endpoint.params.size > 0
        tiny_tmp.params = [] of Param
        endpoint.params.each do |param|
          if !param.name.includes? " "
            if @options[:set_pvalue] != ""
              param.value = @options[:set_pvalue]
            end
            tiny_tmp.params << param
          end
        end
      end

      if tiny_tmp.url != ""
        is_new = true
        final.each do |dup|
          if dup.method == tiny_tmp.method && dup.url == tiny_tmp.url
            is_new = false
            tiny_tmp.params.each do |param|
              existing_param = dup.params.find { |p| p.name == param.name }
              unless existing_param
                dup.params << param
              end
            end
          end
        end
        if is_new || final.size == 0
          final << tiny_tmp
        end
      end
    end

    @endpoints = final
  end

  def combine_url_and_endpoints
    tmp = [] of Endpoint
    target_url = @options[:url]

    if target_url != ""
      @logger.system "Combining url and endpoints."
      @endpoints.each do |endpoint|
        tmp_endpoint = endpoint
        if tmp_endpoint.url.includes? target_url
          tmp_endpoint.url = tmp_endpoint.url.gsub(target_url, "")
        end

        tmp_endpoint.url = tmp_endpoint.url.gsub_repeatedly("//", "/")
        if tmp_endpoint.url != ""
          if target_url[-1] == '/' && tmp_endpoint.url[0] == '/'
            tmp_endpoint.url = tmp_endpoint.url[1..]
          elsif target_url[-1] != '/' && tmp_endpoint.url[0] != '/'
            tmp_endpoint.url = "/#{tmp_endpoint.url}"
          end
        end

        tmp_endpoint.url = target_url + tmp_endpoint.url
        tmp << tmp_endpoint
      end

      @endpoints = tmp
    end
  end

  def deliver
    if @send_proxy != ""
      @logger.system "Sending requests with proxy #{@send_proxy}."
      deliver = SendWithProxy.new(@options)
      deliver.run(@endpoints)
    end

    if @send_req != "no"
      @logger.system "Sending requests without proxy."
      deliver = SendReq.new(@options)
      deliver.run(@endpoints)
    end

    if @send_es != ""
      @logger.system "Sending requests to Elasticsearch."
      deliver = SendElasticSearch.new(@options)
      deliver.run(@endpoints, @send_es)
    end
  end

  def report
    case options[:format]
    when "yaml"
      puts @endpoints.to_yaml
    when "json"
      puts @endpoints.to_json
    when "jsonl"
      builder = OutputBuilderJsonl.new @options
      builder.print @endpoints
    when "markdown-table"
      builder = OutputBuilderMarkdownTable.new @options
      builder.print @endpoints
    when "httpie"
      builder = OutputBuilderHttpie.new @options
      builder.print @endpoints
    when "curl"
      builder = OutputBuilderCurl.new @options
      builder.print @endpoints
    when "oas2"
      buidler = OutputBuilderOas2.new @options
      buidler.print @endpoints
    when "oas3"
      buidler = OutputBuilderOas3.new @options
      buidler.print @endpoints
    when "only-url"
      builder = OutputBuilderOnlyUrl.new @options
      builder.print @endpoints
    when "only-param"
      builder = OutputBuilderOnlyParam.new @options
      builder.print @endpoints
    when "only-header"
      builder = OutputBuilderOnlyHeader.new @options
      builder.print @endpoints
    when "only-cookie"
      builder = OutputBuilderOnlyCookie.new @options
      builder.print @endpoints
    else
      builder = OutputBuilderCommon.new @options
      builder.print @endpoints
    end
  end
end
