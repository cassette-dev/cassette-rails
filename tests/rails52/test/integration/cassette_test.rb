require 'test_helper'

class CassetteTest < ActionDispatch::IntegrationTest
    def reqs(method:, path:, body: nil, content_type: nil, query: [], cookies: {})
        query = query.count > 0 ? "?#{query.join('&')}" : ""
        path = "#{path}#{query}"
        self.send(method, *[path, params: body, as: content_type])
        @response
    end

    test "hello" do
        reqs(
            method: "post",
            path: "/",
            body: nil,
            content_type: :json,
            query: ["hello=world"]
        )
        reqs(
            method: "post",
            path: "/json",
            body: { "hello2": 123 },
            content_type: :json,
            query: ["hello=world"]
        )
        reqs(
            method: "post",
            path: "/",
            body: "hello2=123&world=asdf",
            content_type: "application/x-www-form-urlencoded",
            query: ["hello=world", "ok=1"]
        )
        reqs(
            method: "post",
            path: "/",
            body: { file: fixture_file_upload("#{::Rails.root}/test/fixtures/files/image.png", "image/png") },
            content_type: "multipart/form-data",
            query: ["hello=world"]
        )
        puts ENV["CASSETTE_BULK_FILE_PATH"]
    end
end
