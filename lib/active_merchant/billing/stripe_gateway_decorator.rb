module ActiveMerchant
  module Billing
    module StripeGatewayDecorator
      def verify(source, **options)
        customer = source.gateway_customer_profile_id
        bank_account_token = source.gateway_payment_profile_id

        commit(:post, "customers/#{CGI.escape(customer)}/sources/#{bank_account_token}/verify", amounts: options[:amounts])
      end

      def retrieve(source, **options)
        customer = source.gateway_customer_profile_id
        bank_account_token = source.gateway_payment_profile_id
        commit(:get, "customers/#{CGI.escape(customer)}/bank_accounts/#{bank_account_token}")
      end

      private

      def headers(options = {})
        # headers = super
        # being too lazy here, not me but spree (DUPLICATE just copy/paste ActiveMerchant)
        key = options[:key] || @api_key
        idempotency_key = options[:idempotency_key]

        headers = {
          'Authorization' => 'Basic ' + Base64.strict_encode64(key.to_s + ':').strip,
          'User-Agent' => "Stripe/v1 ActiveMerchantBindings/#{ActiveMerchant::VERSION}",
          'Stripe-Version' => api_version(options),
          'X-Stripe-Client-User-Agent' => stripe_client_user_agent(options),
          'X-Stripe-Client-User-Metadata' => {ip: options[:ip]}.to_json
        }
        headers['User-Agent'] = headers['X-Stripe-Client-User-Agent']
        headers['Idempotency-Key'] = idempotency_key if idempotency_key
        headers['Stripe-Account'] = options[:stripe_account] if options[:stripe_account]
        headers
      end

      def add_destination(post, options)
        if options[:destination]
          post[:transfer_data] = {}
          post[:transfer_data][:destination] = options[:destination]
          post[:transfer_data][:amount] = (options[:destination_amount] - options[:application_fee].to_i) if options[:destination_amount]
        end

        post[:on_behalf_of] = options[:on_behalf_of] if options[:on_behalf_of]
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
