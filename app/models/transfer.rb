class Transfer < AccountOperation
  before_validation :round_amount,
    :on => :create

  after_create :execute

  validates :amount,
    :numericality => true,
    :user_balance => true,
    :minimal_amount => true,
    :maximal_amount => true,
    :negative => true

  validates :currency,
    :inclusion => { :in => ["LRUSD", "LREUR", "EUR", "BTC"] }

  def type_name
    type.gsub(/Transfer/, "").underscore.gsub(/\_/, " ").titleize
  end

  def self.from_params(params)
    transfer = class_for_transfer(params[:currency]).new(params)
    transfer.amount = -transfer.amount.abs

    transfer
  end

  def round_amount
    unless amount.zero?
      self.amount = self.class.round_amount(amount, currency)
    end
  end

  def self.minimal_amount_for(currency)
    currency = currency.to_s.downcase.to_sym

    if [:lrusd, :lreur].include?(currency)
      BigDecimal("0.02")
    elsif currency == :eur
      BigDecimal("30.0")
    elsif currency == :btc
      BigDecimal("0.05")
    else
      raise RuntimeError.new("Invalid currency")
    end
  end  

  def self.round_amount(amount, currency)
    currency = currency.to_s.downcase.to_sym
    amount = amount.to_f if amount.is_a?(Fixnum)
    amount.to_d.round(2, BigDecimal::ROUND_DOWN)
  end
  
  def self.class_for_transfer(currency)
    currency = currency.to_s.downcase.to_sym

    if currency == :eur
      WireTransfer
    elsif [:lrusd, :lreur].include?(currency)
      LibertyReserveTransfer
    elsif currency == :btc
      BitcoinTransfer
    else
      raise RuntimeError.new("Invalid currency")
    end
  end
end