# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by William T. Nelson.

require "io/stream/buffered"

# An IO which fails every operation, as these errors cannot be provoked from a real socket.
class FailingIO
	def initialize(error)
		@error = error
	end
	
	def timeout
		nil
	end
	
	def read_nonblock(size, buffer, exception: false)
		raise @error
	end
	
	def write(buffer)
		raise @error
	end
end

ALostConnection = Sus::Shared("a lost connection") do
	let(:stream) {IO::Stream::Buffered.new(FailingIO.new(error_class))}
	
	it "is translated when reading" do
		expect{stream.read(1)}.to raise_exception(IO::Stream::ConnectionLostError)
	end
	
	it "is translated when writing" do
		expect{stream.write("Hello World", flush: true)}.to raise_exception(IO::Stream::ConnectionLostError)
	end
	
	it "can be retried by consumers which rescue Errno::ECONNRESET" do
		expect{stream.read(1)}.to raise_exception(Errno::ECONNRESET)
	end
	
	it "names the original error" do
		expect{stream.read(1)}.to raise_exception(IO::Stream::ConnectionLostError, message: be =~ /#{error_class.name}/)
	end
	
	it "preserves the original error as the cause" do
		begin
			stream.read(1)
		rescue IO::Stream::ConnectionLostError => error
		end
		
		expect(error.cause).to be_a(error_class)
	end
end

describe IO::Stream::Buffered do
	with "CONNECTION_LOST_ERRORS" do
		it "includes the error raised when the local address is removed" do
			expect(IO::Stream::CONNECTION_LOST_ERRORS).to be(:include?, Errno::EADDRNOTAVAIL)
		end
		
		IO::Stream::CONNECTION_LOST_ERRORS.each do |error|
			with error.name do
				let(:error_class) {error}
				
				it_behaves_like ALostConnection
			end
		end
	end
	
	with "Errno::ECONNRESET" do
		let(:stream) {subject.new(FailingIO.new(Errno::ECONNRESET))}
		
		it "is translated into a connection reset error" do
			expect{stream.read(1)}.to raise_exception(IO::Stream::ConnectionResetError)
		end
	end
	
	with "Errno::EBADF" do
		let(:stream) {subject.new(FailingIO.new(Errno::EBADF))}
		
		it "is translated into a stream closed error" do
			expect{stream.read(1)}.to raise_exception(IOError, message: be =~ /closed/)
		end
	end
end
