class Spree::Gateway::Eghl < Spree::Gateway
  def provider_class
    Spree::Gateway::Eghl
  end
  def payment_source_class
    Spree::CreditCard
  end
end
