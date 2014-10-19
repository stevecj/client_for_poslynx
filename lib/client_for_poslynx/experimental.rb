# coding: utf-8

# Require this file to load experimental features that
# are not yet expected to be fully usable.

# Bit sequence is actually in pretty good shape, but it's
# here because it is only used by SignatureImage.
require "client_for_poslynx/bit_sequence"

# SignatureImage currently only supports the legacy
# Hypercom/Equinox signature data format, which is useful
# to approximately 0% of POSLynx users. It has also not
# been tested with real data produced by a payment terminal,
# so it is possible that some understandings about the
# format are incorrect.
require "client_for_poslynx/signature_image"
