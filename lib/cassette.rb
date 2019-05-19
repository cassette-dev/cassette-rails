require 'uri'

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
        "request.method": request.method,
        "request.path": request.path,
        "request.body": stream_to_string(request.body),
        "request.query": request.GET.map { |k, v| "#{k}=#{v}"},
        "request.cookies": cookies_from_jar(request.cookie_jar),
        "request.headers": relevant_headers(request.headers),
        "response.status": status.to_s,
        "response.body": response.body,
        "response.headers": header_hash_to_list(response_headers),
      }
  
      File.open(bulk_file_path, 'a') { |f| 
        f.flock(File::LOCK_EX)
        f.puts(bulk_file_separator)
        f.puts(URI.encode_www_form(payload))
      }
  
      return status, response_headers, response
    end
  
    def relevant_headers(env)
      relevant = env.select { |k,v| (k.start_with? 'HTTP_' or k.upcase == "CONTENT_TYPE") and k.upcase != "HTTP_COOKIE" }
      header_hash_to_list(relevant)
    end
  
    def header_hash_to_list(hash)
      hash.collect {|k,v| [k.sub(/^HTTP_/, ''), v]}
        .collect {|k,v| [k.downcase.sub('_', '-'), v]}
        .map { |k, v| "#{k}=#{v}"}
    end
  
    def stream_to_string(stream)
      stream.rewind
      str = stream.read.to_s
      stream.rewind
      return str
    end
  
    def cookies_from_jar(cookie_jar)
      cookies = []
      cookie_jar.each { |cookie| cookies << "#{cookie[0]}=#{cookie[1]}" }
      cookies
    end
end
