module Spree
  module Gateway::PaypalCapture

    PAYPAL_TEST_API = "https://api-m.sandbox.paypal.com"
    PAYPAL_LIVE_API = "https://api-m.paypal.com"

    def paypal_capture_payment(source)
      return source_not_found if source.blank?
      @source = source
      @auth = authorization
      capture_order
    end

    private
    def paypal_api
      preferred_test_mode ? PAYPAL_TEST_API : PAYPAL_LIVE_API
    end

    def source_not_found
      json_response('source not found')
    end

    def json_response(message, success = false, response = nil )
      { success: success, message: message, response: response }
    end

    def capture_order
      response = HTTParty.post("#{paypal_api}/v2/payments/authorizations/#{@source.transaction_id}/capture", 
              headers: {
                "Content-Type": 'application/json',
                "Authorization": "Bearer #{ @auth['access_token'] }"
              }
            )
      json_response(response.message, response.success?, response)
    rescue => e
      Rails.logger.error(e.message)
      json_response(e.message)
    end

    def authorization
      basicAuth = Base64.strict_encode64("#{ preferred_client_id }:#{ preferred_client_secret }")
      response = HTTParty.post("#{paypal_api}/v1/oauth2/token/", 
          headers: {
            "Content-Type": 'application/x-www-form-urlencoded',
            "Authorization": "Basic #{ basicAuth }"
          },
          body: "grant_type=client_credentials"
        )
      response.parsed_response
    rescue => e
      Rails.logger.error(e.message)
      json_response(e.message)
    end

  end
end