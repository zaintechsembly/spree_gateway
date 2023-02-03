module Spree
  module Gateway::PaypalExpress

    PAYPAL_TEST_API = "https://api-m.sandbox.paypal.com"
    PAYPAL_LIVE_API = "https://api-m.paypal.com"

    def paypal_capture_payment(payment)
      @transaction_id = payment.source.transaction_id
      @paypal = payment.order.store.paypal_gateway
      @auth = authorization
      capture_order
    end

    private
    def paypal_api
      @paypal.preferred_test_mode ? PAYPAL_TEST_API : PAYPAL_LIVE_API
    end

    def capture_order
      HTTParty.post("#{paypal_api}/v2/payments/authorizations/#{@transaction_id}/capture", 
        headers: {
          "Content-Type": 'application/json',
          "Authorization": "Bearer #{ @auth['access_token'] }"
        }
      );
    rescue => e
      Rails.logger.error(e.message)
    end

    def authorization
      basicAuth = Base64.strict_encode64("#{ @paypal.preferred_client_id }:#{ @paypal.preferred_client_secret }");
      res = HTTParty.post("#{paypal_api}/v1/oauth2/token/", 
          headers: {
            "Content-Type": 'application/x-www-form-urlencoded',
            "Authorization": "Basic #{ basicAuth }"
          },
          body: "grant_type=client_credentials"
        );
      res.parsed_response
    rescue => e
      Rails.logger.error(e.message)
    end

  end
end