module Spree
  module Gateway::PaypalCapture

    PAYPAL_TEST_API = "https://api-m.sandbox.paypal.com"
    PAYPAL_LIVE_API = "https://api-m.paypal.com"

    def paypal_capture_payment(payment)
      @payment = payment
      @source = @payment&.source
      return json_response('source not found') if @source.blank?

      authorization && validate_payment ? capture_order : json_response("Something went wrong!")
    end

    private
    def paypal_api
      preferred_test_mode ? PAYPAL_TEST_API : PAYPAL_LIVE_API
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

    def validate_payment
      transaction = fetch_authorization
      return false unless transaction.success?

      transaction["amount"]["currency_code"] == @payment.order.currency.upcase &&
        transaction["amount"]["value"].to_f == @payment.order.price_values[:prices][:payable_amount].to_f
    end

    def fetch_authorization
      paypal_api = "https://api-m.sandbox.paypal.com"

      HTTParty.get("#{paypal_api}/v2/payments/authorizations/#{@source.transaction_id}", 
        headers: {
          "Content-Type": 'application/json',
          "Authorization": "Bearer #{ @auth['access_token'] }"
        }
      )
    rescue => exception
      Rails.logger.error(exception.message)
      json_response(exception.message)
    end

    def authorization
      paypal_api = "https://api-m.sandbox.paypal.com"

      basicAuth = Base64.strict_encode64("#{ pm.preferred_client_id }:#{ pm.preferred_client_secret }")
      response = HTTParty.post("#{paypal_api}/v1/oauth2/token/", 
                  headers: {
                    "Content-Type": 'application/x-www-form-urlencoded',
                    "Authorization": "Basic #{ basicAuth }"
                  },
                  body: "grant_type=client_credentials"
                )

      @auth = response.parsed_response
    rescue => e
      Rails.logger.error(e.message)
      json_response(e.message)
    end

  end
end