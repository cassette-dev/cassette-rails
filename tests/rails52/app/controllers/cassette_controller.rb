class CassetteController < ApplicationController
    def index
        render json: { hello: "world" }
    end

    def json
        render json: { hello: "world" }
    end
end
