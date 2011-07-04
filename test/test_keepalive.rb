require File.expand_path('base_test_case', File.dirname(__FILE__))
require 'socket'

class TestKeepalive < Test::Unit::TestCase
  include BaseTestCase

  def config_test_different_operation_with_keepalive
    @keepalive = 'on'
  end

  def test_different_operation_with_keepalive
    channel = 'ch_test_different_operation_with_keepalive'
    body = 'message to be sent'

    get_without_channel_id = "GET /pub HTTP/1.0\r\n\r\n"
    post_channel_message = "POST /pub?id=#{channel} HTTP/1.0\r\nContent-Length: #{body.size}\r\n\r\n#{body}"
    get_channels_stats = "GET /channels-stats HTTP/1.0\r\n\r\n"
    get_channel_stats = "GET /pub?id=#{channel} HTTP/1.0\r\n\r\n"

    socket = TCPSocket.open(nginx_host, nginx_port)

    socket.print(get_without_channel_id)
    headers, body = read_response(socket)
    assert_equal("", body, "Wrong response")
    assert(headers.index('No channel id provided.') > 0, "Didn't receive error message")

    socket.print(post_channel_message)
    headers, body = read_response(socket)
    assert_equal("{\"channel\": \"#{channel}\", \"published_messages\": \"1\", \"stored_messages\": \"1\", \"subscribers\": \"0\"}\r\n", body, "Wrong response")

    socket.print(get_channels_stats)
    headers, body = read_response(socket)
    assert(body.index("\"channels\": \"1\", \"broadcast_channels\": \"0\", \"published_messages\": \"1\", \"subscribers\": \"0\", \"by_worker\": [\r\n") > 0, "Didn't receive message")
    assert(body.index("\"subscribers\": \"0\"}") > 0, "Didn't receive message")

    socket.print(get_channel_stats)
    headers, body = read_response(socket)
    assert_equal("{\"channel\": \"#{channel}\", \"published_messages\": \"1\", \"stored_messages\": \"1\", \"subscribers\": \"0\"}\r\n", body, "Wrong response")

  end

  def read_response(socket)
    response = socket.readpartial(1)
    while (tmp = socket.read_nonblock(256))
      response += tmp
    end
  ensure
    fail("Any response") if response.nil?
    headers, body = response.split("\r\n\r\n", 2)
    return headers, body
  end
end
