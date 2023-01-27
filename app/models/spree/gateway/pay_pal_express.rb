module Spree
  class Gateway::PayPalExpress < Gateway
    preference :client_id, :string
    preference :server, :string, default: 'sandbox'
    preference :solution, :string, default: 'Mark'
    preference :landing_page, :string, default: 'Billing'
    preference :logourl, :string, default: ''

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
