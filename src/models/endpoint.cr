require "json"
require "yaml"

struct Endpoint
  include JSON::Serializable
  include YAML::Serializable
  property url, method, params, protocol, details, tags

  def initialize(@url : String, @method : String)
    @params = [] of Param
    @details = Details.new
    @protocol = "http"
    @tags = [] of Tag
  end

  def initialize(@url : String, @method : String, @details : Details)
    @params = [] of Param
    @protocol = "http"
    @tags = [] of Tag
  end

  def initialize(@url : String, @method : String, @params : Array(Param))
    @details = Details.new
    @protocol = "http"
    @tags = [] of Tag
  end

  def initialize(@url : String, @method : String, @params : Array(Param), @details : Details)
    @protocol = "http"
    @tags = [] of Tag
  end

  def set_details(@details : Details)
  end

  def set_protocol(protocol : String)
    @protocol = protocol
  end

  def add_tag(tag : Tag)
    @tags << tag
  end

  def push_param(param : Param)
    @params << param
  end

  def params_to_hash
    params_hash = {} of String => Hash(String, String)
    params_hash["query"] = {} of String => String
    params_hash["json"] = {} of String => String
    params_hash["form"] = {} of String => String

    @params.each do |param|
      params_hash[param.param_type][param.name] = param.value
    end

    params_hash
  end
end

struct Param
  include JSON::Serializable
  include YAML::Serializable
  property name, value, param_type, tags

  # param_type can be "query", "json", "form", "header", "cookie"

  def initialize(@name : String, @value : String, @param_type : String)
    @tags = [] of Tag
  end

  def add_tag(tag : Tag)
    @tags << tag
  end
end

struct Details
  include JSON::Serializable
  include YAML::Serializable
  property code_paths : Array(PathInfo) = [] of PathInfo

  # + New details types to be added in the future..

  def initialize
  end

  def initialize(code_path : PathInfo)
    @code_paths << code_path
  end

  def add_path(code_path : PathInfo)
    @code_paths << code_path
  end

  def ==(other : Details) : Bool
    return false if @code_paths.size != other.code_paths.size
    return false unless @code_paths.all? { |path| other.code_paths.any? { |other_path| path == other_path } }
    true
  end
end

struct PathInfo
  include JSON::Serializable
  include YAML::Serializable
  property path, line

  def initialize(@path : String)
    @line = nil
  end

  def initialize(@path : String, @line : Int32 | Nil)
  end

  def ==(other : PathInfo) : Bool
    @path == other.path && @line == other.line
  end
end

struct EndpointReference
  include JSON::Serializable
  property endpoint, metadata

  def initialize(@endpoint : Endpoint, @metadata : Hash(Symbol, String))
  end
end

struct Tag
  include JSON::Serializable
  include YAML::Serializable
  property name, description, tagger

  def initialize(@name : String, @description : String, @tagger : String)
  end
end
