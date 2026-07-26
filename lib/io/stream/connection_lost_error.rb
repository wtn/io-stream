# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by William T. Nelson.

module IO::Stream
	# Represents a connection which can no longer be used, usually because the local address was removed or the route to the peer was lost. It is a connection reset error so that existing consumers, which retry idempotent requests on reset, handle it without modification.
	class ConnectionLostError < Errno::ECONNRESET
	end
	
	# The system call errors which indicate the connection is lost. Not every error is defined on every platform.
	CONNECTION_LOST_ERRORS = [
		:EADDRNOTAVAIL,
		:ECONNABORTED,
		:EHOSTDOWN,
		:EHOSTUNREACH,
		:ENETDOWN,
		:ENETRESET,
		:ENETUNREACH,
		:ETIMEDOUT,
	].filter_map{|name| Errno.const_get(name) if Errno.const_defined?(name, false)}.freeze
end
