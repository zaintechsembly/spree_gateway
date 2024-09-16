module Spree
  class Gateway::AdyenGateway < Gateway
    # checkout servcice credentials
    preference :public_key, :string
    preference :api_username, :string
    preference :api_password, :string
    preference :merchant_account, :string
    preference :live_url_prefix, :string
    # configured for each store (removed from payment method)
    # preference :client_key, :string # term: origin key

    # marketpay servcice credentials
    preference :ws_user, :string
    preference :ws_password, :string
    preference :api_key, :string
    # webhook credentials
    preference :adyen_hmac_key, :string
    preference :webhook_user, :string
    preference :webhook_password, :string

    def auto_capture?
      false
    end

    # As adyen conferm refund using webhook after creating refund successfully
    def webhook_refund?
      true
    end

    def method_type
      'adyen'
    end

    def provider_class
      ActiveMerchant::Billing::AdyenGateway
    end

    def payment_source_class
      Spree::AdyenCheckout
    end

    def supports?(source)
      return true unless provider_class.respond_to? :supports?
      return false unless source.brand

      provider_class.supports?(source.brand)
    end

    # NOTE Override this with your custom logic for scenarios where you don't
    # want to redirect customer to 3D Secure auth
    # def require_3d_secure?(payment)
    #   true
    # end

    def purchase(money, creditcard, gateway_options)
      # provider.purchase(*options_for_purchase_or_auth(money, creditcard, gateway_options))
      provider.authorize(*options_for_purchase_or_auth(money, creditcard, gateway_options))
    end

    def authorize(money, creditcard, gateway_options)
      provider.authorize(*options_for_purchase_or_auth(money, creditcard, gateway_options))
    end

    def capture(money, response_code, gateway_options)
      provider.capture(money, response_code, gateway_options)
    end

    # def credit(money, creditcard, response_code, gateway_options)
    def credit(money, response_code, gateway_options)
      provider.refund(money, response_code, refund_options(gateway_options, money))
    end

    def void(response_code, gateway_options)
      provider.void(response_code, gateway_options)
    end

    def cancel(response_code)
      provider.void(response_code, {})
    end

    def authorize3d(money, source, gateway_options)
      provider.authorize3d(source)
    end

    def webhook_token
      Base64.strict_encode64("#{preferred_webhook_user}:#{preferred_webhook_password}")
    end

    def webhook_configured?
      (preferred_webhook_user.present? && preferred_webhook_password.present?) || preferred_adyen_hmac_key.present?
    end

    private
    def refund_options(gateway_options, money)
      gateway_options.merge!(
        amount: money,
        currency: gateway_options[:originator].payment.currency,
        webhook_configured: webhook_configured?
      )
    end

    def options
      super.merge(
        username: preferred_api_username,
        password: preferred_api_password,
        merchant_account: preferred_merchant_account
      )
    end

    def options_for_purchase_or_auth(money, creditcard, gateway_options)
      options = { recurring: false }
      options[:order_id] = gateway_options[:order_reference_id]
      options[:currency] = gateway_options[:currency]
      options[:return_url] = "api/v2/storefront/checkout?order_token=#{gateway_options[:order_token]}"
      options[:channel] = "web"
      options[:amount] = money
      options[:billing_address] = gateway_options[:billing_address]
      options[:splits] = gateway_options[:splits]

      store_url = gateway_options[:store_url]
      options[:site_origin] = if store_url && store_url["https://"].nil?
                                "https://" + store_url
                              else
                                store_url
                              end

      options[:shopperReference] = if gateway_options[:customer_id].present?
                                     gateway_options[:customer_id]
                                   else
                                     gateway_options[:email]
                                   end

      if customer = creditcard.gateway_customer_profile_id
        options[:customer] = customer
      end
      if token_or_card_id = creditcard.gateway_payment_profile_id
        creditcard = token_or_card_id
      end

      return money, creditcard, options
    end
  end
end
