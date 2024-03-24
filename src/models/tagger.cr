require "./logger"

class Tagger
  @logger : NoirLogger
  @options : Hash(Symbol, String)
  @is_debug : Bool
  @is_color : Bool
  @is_log : Bool

  def initialize(options : Hash(Symbol, String))
    @is_debug = str_to_bool(options[:debug])
    @options = options
    @is_color = str_to_bool(options[:color])
    @is_log = str_to_bool(options[:nolog])

    @logger = NoirLogger.new @is_debug, @is_color, @is_log
  end

  def perform(endpoints : Array(Endpoint)) : Array(Endpoint)
    # After inheriting the class, write an action code here.

    endpoints
  end
end
