class Samurai::PaymentMethod < Samurai::Base
  
  include Samurai::CacheableByToken

  def id # :nodoc:
    self.token
  end
  
  # Alias for +payment_method_token+
  def token
    self.payment_method_token
  end
  
  # Retains the payment method on samurai.feefighters.com. Retain a payment method if 
  # it will not be used immediately. 
  def retain
    self.post(:retain)
  end
  
  # Redacts sensitive information from the payment method, rendering it unusable.
  def redact
    self.post(:redact)
  end
  
  # Retrieves JSON formatted custom data that is encoded in the custom_data attribute
  def custom_json_data
    @custom_data ||= self.custom && (JSON.parse(self.custom) rescue {}).symbolize_keys
  end

  def process_response_errors
    if respond_to?(:messages) && self.messages
      self.messages.each do |message|
        #if (message.respond_to?(:subclass) && message.subclass == 'error')
          self.errors.add message.context.gsub(/\./, ' '), message.key
        #end
      end
    end
  end
  protected :process_response_errors

  KNOWN_ATTRIBUTES = [
    :first_name, :last_name, :address_1, :address_2, :city, :state, :zip,
    :card_number, :cvv, :expiry_month, :expiry_year
  ]
  if ActiveResource::VERSION::MAJOR <= 3 && ActiveResource::VERSION::MINOR < 1
    # If we're using ActiveResource pre-3.1, there's no schema class method, so we resort to some tricks...
    # Initialize the known attributes from the schema as empty strings, so that they can be accessed via method-missing
    EMPTY_ATTRIBUTES = KNOWN_ATTRIBUTES.inject(ActiveSupport::HashWithIndifferentAccess.new) {|h, k| h[k] = ''; h}
    def initialize(attrs={})
      super(EMPTY_ATTRIBUTES.merge(attrs))
    end
  else
    # Post AR 3.1, we can use the schema method to define our attributes
    schema do
      string *KNOWN_ATTRIBUTES
    end
  end

  # Prepare a new PaymentMethod for use with a transparent redirect form
  def self.for_transparent_redirect(params)
    if params[:payment_method_token].blank?
      Samurai::PaymentMethod.new(params)
    else
      Samurai::PaymentMethod.find(params[:payment_method_token]).tap do |pm|
        pm.card_number = "************#{pm.last_four_digits}"
        pm.cvv = "***"
        pm.errors[:base] << 'The card number or CVV are not valid.' if !pm.is_sensitive_data_valid
      end
    end
  end

end
