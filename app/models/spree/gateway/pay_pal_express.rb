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

    def manual_capture? order_token
      Spree::Order.find_by(token: order_token).store.paypal_gateway.present?
    end

    def manual_capture(amount, gateway_options)
      order = Spree::Order.find_by(token: gateway_options[:order_token])
      paypal_payment = order.payments.joins(:payment_method)
                            .where('spree_payment_methods.type = ?', 'Spree::Gateway::PayPalExpress')
                            .pending.last
      return { success: false } if paypal_payment&.source.blank? 
      # Capture amount
      res = paypal_capture_payment(paypal_payment)
      res&.success? ? paypal_payment.complete : paypal_payment.failure
      { success: paypal_payment.completed? }
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
