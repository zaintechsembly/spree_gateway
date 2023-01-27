module Spree
  class Gateway::Eghl < Gateway

    def provider_class
      Gateway::Eghl
    end
    
    def payment_source_class
      CreditCard
    end
  end
end