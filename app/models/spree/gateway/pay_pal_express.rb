module Spree
  class Gateway::PayPalExpress < Gateway

    include PaypalCapture
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

    def manual_capture(amount, source, gateway_options)
      paypal_capture_payment(source)
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
