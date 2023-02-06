module Spree
  class Gateway::PayPalExpress < Gateway

    include PaypalExpress
    preference :client_id, :string
    preference :client_secret, :string
    preference :server, :string, default: 'sandbox'
    preference :solution, :string, default: 'Mark'
    preference :landing_page, :string, default: 'Billing'
    preference :logourl, :string, default: ''
    preference :test_mode, :boolean, default: true

    def manual_capture?
      true
    end

    def manual_capture(amount, gateway_options)
      payment = gateway_options[:payment]
      return {success: false, message: 'source not found'} if payment&.source.blank?
      paypal_capture_payment(payment)
    end

    def auto_capture?
      true
    end

    def supports?(source)
      true
    end

    def method_type
      'paypal'
    end

  end
end
