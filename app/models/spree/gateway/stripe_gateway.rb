module Spree
  class Gateway::StripeGateway < Gateway
    preference :secret_key, :string
    preference :publishable_key, :string
    preference :client_key, :string

    CARD_TYPE_MAPPING = {
      'American Express' => 'american_express',
      'Diners Club' => 'diners_club',
      'Discover' => 'discover',
      'JCB' => 'jcb',
      'Laser' => 'laser',
      'Maestro' => 'maestro',
      'MasterCard' => 'master',
      'Solo' => 'solo',
      'Switch' => 'switch',
      'Visa' => 'visa'
    }

    def method_type
      'stripe'
    end

    def auto_capture?
      true
    end

    def manual_capture? order_token
      return false # resrited for now
      order = Spree::Order.find_by(token: order_token)
      order.store.stripe_gateway.present? && order.payment_intent_id.present? 
    end

    def supports?(source)
      true
    end

    def provider_class
      ActiveMerchant::Billing::StripeGateway
    end

    def payment_profiles_supported?
      true
    end

    def purchase(money, creditcard, gateway_options)
      provider.purchase(*options_for_purchase_or_auth(money, creditcard, gateway_options))
    end

    def authorize(money, creditcard, gateway_options)
      provider.authorize(*options_for_purchase_or_auth(money, creditcard, gateway_options))
    end

    def manual_capture(amount, gateway_options)
      # Capture amount
      order = Spree::Order.find_by(token: gateway_options[:order_token])
      Stripe.api_key = preferred_secret_key
      Stripe.stripe_account = order.store.send(:stripe_connected_account)
      begin
        Stripe::PaymentIntent.capture(order.payment_intent_id)
        { success: true, message: 'Transaction approved' }
      rescue => exception
        Rails.logger.error(exception.message)
        { success: false, message: exception.message }
      end
    end

    def capture(money, response_code, gateway_options)
      provider.capture(money, response_code, gateway_options)
    end

    def credit(money, creditcard, response_code, gateway_options)
      provider.refund(money, response_code, {})
    end

    def void(response_code, creditcard, gateway_options)
      provider.void(response_code, {})
    end

    def cancel(response_code)
      provider.void(response_code, {})
    end

    def create_profile(payment)
      stripe_customer = Stripe::Customer.create({ name: payment.order.customer_name, email: payment.order.email })
      payment_intent_attrs = { customer: stripe_customer.id }

      stripe_payment = order.payments.joins(:payment_method)
                            .where('spree_payment_methods.type = ?', 'Spree::Gateway::StripeGateway')
                            .completed.last

      # update description if successfully paid
      payment_intent_attrs[:description] = "Techsembly Order ID: #{order.number}-#{stripe_payment.number}" if stripe_payment.present?

      Stripe::PaymentIntent.update(order.payment_intent_id, payment_intent_attrs)

    end

    private

    # In this gateway, what we call 'secret_key' is the 'login'
    def options
      super.merge(
        login: preferred_secret_key,
        application: app_info
      )
    end

    def options_for_purchase_or_auth(money, creditcard, gateway_options)
      options = {}
      options[:description] = gateway_options[:order_reference_id]
      options[:currency] = gateway_options[:currency]
      options[:application] = app_info
      options[:stripe_account] = gateway_options[:stripe_account]
      options[:destination] = gateway_options[:destination]
      options[:destination_amount] = gateway_options[:destination_amount]
      options[:on_behalf_of] = gateway_options[:on_behalf_of]
      options[:application_fee] = gateway_options[:application_fee]

      if customer = creditcard.gateway_customer_profile_id
        options[:customer] = customer
      end
      if token_or_card_id = creditcard.gateway_payment_profile_id
        # The Stripe ActiveMerchant gateway supports passing the token directly as the creditcard parameter
        # The Stripe ActiveMerchant gateway supports passing the customer_id and credit_card id
        # https://github.com/Shopify/active_merchant/issues/770
        creditcard = token_or_card_id
      end
      return money, creditcard, options
    end

    def address_for(payment)
      {}.tap do |options|
        if address = payment.order.bill_address
          options.merge!(address: {
            address1: address.address1,
            address2: address.address2,
            city: address.city,
            zip: address.zipcode
          })

          if country = address.country
            options[:address].merge!(country: country.name)
          end

          if state = address.state
            options[:address].merge!(state: state.name)
          end
        end
      end
    end

    def update_source!(source)
      source.cc_type = CARD_TYPE_MAPPING[source.cc_type] if CARD_TYPE_MAPPING.include?(source.cc_type)
      source
    end

    def app_info
      name_with_version = "SpreeGateway/#{SpreeGateway.version}"
      url = 'https://spreecommerce.org'
      "#{name_with_version} #{url}"
    end
  end
end
