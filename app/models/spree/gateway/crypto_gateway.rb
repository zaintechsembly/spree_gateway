module Spree
  class Gateway::CryptoGateway < Gateway
    preference :secret_key, :string
    preference :publishable_key, :string

    def auto_capture?
      true
    end

    def payment_processable?
      false
    end

    def cancel(response); end

    def payment_source_class
      Spree::CryptoWallet
    end

    def provider_class
      Spree::Gateway::CryptoGateway
    end

  end
end
