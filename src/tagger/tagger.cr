require "./taggers/*"
require "../models/tagger"

macro defind_taggers(taggers)
  {% for tagger, index in taggers %}
    instance = {{tagger}}.new(options)
    tagger_list << instance
  {% end %}
end

def run_tagger(endpoints : Array(Endpoint), options : Hash(Symbol, String))
  tagger_list = [] of Tagger

  # Define taggers
  defind_taggers([
    HuntParamTagger,
  ])

  # Run taggers
  tagger_list.each do |tagger|
    tagger.perform(endpoints)
  end
end
