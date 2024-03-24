require "../../models/tagger"
require "../../models/endpoint"

class HuntParamTagger < Tagger
  TAG_DEFINITIONS = {
    "ssti" => {
      "words"       => ["template", "preview", "id", "view", "activity", "name", "content", "redirect"],
      "description" => "This parameter may be vulnerable to Server Side Template Injection (SSTI) attacks.",
    },
    "ssrf" => {
      "words"       => ["dest", "redirect", "uri", "path", "continue", "url", "window", "next", "data", "reference", "site", "html", "val", "validate", "domain", "callback", "return", "page", "feed", "host", "port", "to", "out", "view", "dir", "show", "navigation", "open"],
      "description" => "This parameter may be vulnerable to Server Side Request Forgery (SSRF) attacks.",
    },
    "sqli" => {
      "words"       => ["id", "select", "report", "role", "update", "query", "user", "name", "sort", "where", "search", "params", "process", "row", "view", "table", "from", "sel", "results", "sleep", "fetch", "order", "keyword", "column", "field", "delete", "string", "number", "filter"],
      "description" => "This parameter may be vulnerable to SQL Injection attacks.",
    },
    "idor" => {
      "words"       => ["id", "user", "account", "number", "order", "no", "doc", "key", "email", "group", "profile", "edit", "report"],
      "description" => "This parameter may be vulnerable to Insecure Direct Object Reference (IDOR) attacks.",
    },
    "file-inclusion" => {
      "words"       => ["file", "document", "folder", "root", "path", "pg", "style", "pdf", "template", "php_path", "doc"],
      "description" => "This parameter may be vulnerable to File Inclusion attacks.",
    },
    "debug" => {
      "words"       => ["access", "admin", "dbg", "debug", "edit", "grant", "test", "alter", "clone", "create", "delete", "disable", "enable", "exec", "execute", "load", "make", "modify", "rename", "reset", "shell", "toggle", "adm", "root", "cfg", "config"],
      "description" => "This parameter may be vulnerable to Debug method exploits.",
    },
    "command-injection" => {
      "words"       => ["daemon", "host", "upload", "dir", "execute", "download", "log", "ip", "cli", "cmd"],
      "description" => "This parameter may be vulnerable to Command Injection attacks.",
    },
  }

  def perform(endpoints : Array(Endpoint))
    tagger = {} of String => Hash(String, Array(String) | String)
    TAG_DEFINITIONS.each do |key, value|
      tagger[key] = {"words" => value["words"], "description" => value["description"]}
    end

    endpoints.each do |endpoint|
      endpoint.params.each do |param|
        TAG_DEFINITIONS.each do |k, v|
          if v["words"].includes? param.name
            tag = Tag.new(k, v["description"].to_s, "Hunt")
            param.add_tag(tag)
          end
        end
      end
    end
  end
end
