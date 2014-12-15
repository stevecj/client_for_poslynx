# coding: utf-8

module ClientForPoslynx
  module Data
    module Requests

      module CanVisit

        def visit_CreditCardSale(visitee)             ; visit_general visitee ; end
        def visit_DebitCardSale(visitee)              ; visit_general visitee ; end
        def visit_PinPadInitialize(visitee)           ; visit_general visitee ; end
        def visit_PinPadReset(visitee)                ; visit_general visitee ; end
        def visit_PinPadDisplayMessage(visitee)       ; visit_general visitee ; end
        def visit_PinPadDisplaySpecifiedForm(visitee) ; visit_general visitee ; end
        def visit_PinPadGetSignature(visitee)         ; visit_general visitee ; end

        def visit_general(visitee) ; end

      end

    end
  end
end
