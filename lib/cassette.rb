require 'uri'
require "base64"
require 'json'

class CassetteMiddleware
    def initialize app
      @app = app
    end

    def call(env)
      if ENV["CASSETTE_RECORDING"] != "1"
        return @app.call(env)
      end
  
      bulk_file_path = ENV["CASSETTE_BULK_FILE_PATH"]
      bulk_file_separator = ENV["CASSETTE_BULK_FILE_SEPARATOR"]
  
      request = ActionDispatch::Request.new(env)
      status, response_headers, response = @app.call(env)
      payload = {
        "path": request.path,
        "method": request.method,
        "status": status,
        "request_query": request.query_string,
        "request_body": Base64.encode64(stream_to_string(request.body)),
        "request_cookies": cookies_from_jar(request.cookie_jar),
        "request_headers": relevant_headers(request.headers),
        "response_body": Base64.encode64(response.body),
        "response_headers": header_hash_to_dict(response_headers),
      }
  
      File.open(bulk_file_path, 'a') { |f| 
        f.flock(File::LOCK_EX)
        f.puts(bulk_file_separator)
        f.puts(JSON.generate(payload))
      }
  
      return status, response_headers, response
    end
  
    def relevant_headers(env)
      relevant = env.select { |k,v| (k.start_with? 'HTTP_' or k.upcase == "CONTENT_TYPE") and k.upcase != "HTTP_COOKIE" }
      header_hash_to_dict(relevant)
    end
  
    def header_hash_to_dict(hash)
      headers = hash.collect {|k,v| [k.sub(/^HTTP_/, ''), v]}
        .collect {|k,v| [k.downcase.sub('_', '-'), v]}

      next_headers = Hash.new { |hash, key| hash[key] = [] }
      headers.each { |header| next_headers[header[0]] << header[1] }
      next_headers
    end
  
    def stream_to_string(stream)
      stream.rewind
      str = stream.read.to_s
      stream.rewind
      return str
    end
  
    def cookies_from_jar(cookie_jar)
      cookies = Hash.new { |hash, key| hash[key] = [] }
      cookie_jar.each { |cookie| cookies[cookie[0]] << cookie[1] }
      cookies
    end
end
