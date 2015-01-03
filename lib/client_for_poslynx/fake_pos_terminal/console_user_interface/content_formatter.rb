# coding: utf-8

require 'delegate'

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface

      module ContentFormatter
        extend self

        extend FakePosTerminal::ValueFormatting

        def multiline_message(text_lines)
          centered_lines = text_lines.map { |text| text.center(68) }
          "\n" << centered_lines * "\n" << "\n\n"
        end

        def buttons(button_labels)
          button_strings = button_labels.map { |label| "[ #{label} ]" }
          tot_button_space = button_strings.map(&:length).inject{ |m, length| m + length }
          tot_marginal_space = 68 - tot_button_space
          padding_size = tot_marginal_space / ( button_strings.length * 2 )
          padding = ' ' * padding_size
          button_strings.map! { |string| padding + string + padding }
          ( button_strings * '' ).center( 68 )
        end

        def welcome_with_idle_prompt(prompt)
'
                        ___       _    _            ___
             |   |   | |    |    / \  / \  |     | |
             |   |   | |    |   |    |   | |\   /| |    
             |   |   | |--  |   |    |   | | \ / | |--
             |  / \  | |    |   |    |   | |  |  | |    
              \/   \/  |___ |___ \_/  \_/  |  |  | |___

' + "  (#{prompt})\n"
        end

        def signature_entry_box
'

      Sign here...
     -----------------------------------------------------------
    |                                                           |
    |                                                           |
    |                                                           |
     -----------------------------------------------------------

'
        end

        def payment_confirmation(amount)
          lines = []
          lines << "TOTAL AMOUNT"
          lines << format_usd( amount )
          multiline_message(lines)
        end

        def card_swipe_request(request_data)
          total       = request_data.amount
          transaction = 'PURCHASE'
          lines = []
          lines << "Please swipe your card"
          lines << "Total: " + format_usd( total ) if total
          lines << "Transaction: " + transaction
          multiline_message( lines )
        end

      end

    end
  end
end
