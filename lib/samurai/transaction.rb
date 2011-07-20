class Samurai::Transaction < Samurai::Base
  
  include Samurai::CacheableByToken
  
  # Alias for transaction_token
  def id # :nodoc:
    transaction_token
  end
  
  # Captures an authorization. Optionally specify an +amount+ to do a partial capture of the initial
  # authorization. The default is to capture the full amount of the authroization.
  def capture(amount = nil)
    resp = post(:capture, {}, self.class.transaction_payload(:amount => amount || self.amount))
    # return the response, wrapped in a Samurai::Transaction
    Samurai::Transaction.new.load_attributes_from_response(resp)
  end
  
  # Void this transaction. If the transaction has not yet been captured and settled it can be voided to 
  # prevent any funds from transfering. 
  def void
    resp = post(:void, {}, self.class.transaction_payload())
    # return the response, wrapped in a Samurai::Transaction
    Samurai::Transaction.new.load_attributes_from_response(resp)
  end
  
  # Create a credit or refund against the original transaction.
  # Optionally accepts an +amount+ to credit, the default is to credit the full 
  # value of the original amount
  def credit(amount = nil)
    resp = post(:credit, {}, self.class.transaction_payload(:amount => amount || self.amount))
    # return the response, wrapped in a Samurai::Transaction
    Samurai::Transaction.new.load_attributes_from_response(resp)
  end
  
  private
  
  # Builds an xml payload that represents the transaction data to submit to samuari.feefighters.com
  def self.transaction_payload(options = {})
    {
      :amount => options[:amount],
      :type => options[:type],
      :payment_method_token => options[:payment_method_token],
      :currency_code => options[:currency_code] || (options[:payment_method_token] && 'USD'), # currency code is only required for payloads that include the PMT
      :descriptor => options[:descriptor],
      :custom => options[:custom]
    }.
      reject{ |k,v| v.nil? }.
      to_xml(:skip_instruct => true, :root => 'transaction', :dasherize => false)
  end
  
end