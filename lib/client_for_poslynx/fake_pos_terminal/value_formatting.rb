# coding: utf-8

require 'bigdecimal'

module ClientForPoslynx
  module FakePosTerminal

    module ValueFormatting

      def format_usd(value)
        value = BigDecimal( value )
        decimal = '%.2f' % value
        mantissa, fraction = decimal.split('.')
        mantissa = mantissa.reverse.gsub(/\d\d\d(?=\d)/, '\&,').reverse
        "$#{mantissa}.#{fraction}"
      end

    end

  end
end
