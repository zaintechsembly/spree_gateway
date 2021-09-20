module ActiveMerchant
  module Billing
    module StripeGatewayDecorator
      private

      def headers(options = {})
        headers = super
        headers['User-Agent'] = headers['X-Stripe-Client-User-Agent']
        headers['Stripe-Account'] = options[:stripe_account] if options[:stripe_account]
        headers
      end

      def add_destination(post, options)
        if options[:destination]
          post[:transfer_data] = {}
          post[:transfer_data][:destination] = options[:destination]
          post[:transfer_data][:amount] = (options[:destination_amount] - options[:application_fee].to_i) if options[:destination_amount]
        end
        # FIXME it's here because active merchant billing adds emv checks before adding application_fee
        post[:application_fee] = options[:application_fee] if options[:application_fee]
      end

      def add_customer_data(post, options)
        super
        post[:payment_user_agent] = "SpreeGateway/#{SpreeGateway.version}"
      end
    end
  end
end

ActiveMerchant::Billing::StripeGateway.prepend(ActiveMerchant::Billing::StripeGatewayDecorator)
