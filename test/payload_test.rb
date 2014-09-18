require "test/unit"

require_relative "../lib/payload"

class PayloadTest < Test::Unit::TestCase
  def test_proper
    params = {
      "content" => "",
      "commit_message" => "Adding",
      "type" => "file"
    }

    assert_equal params, Payload.extract(params)
  end

  def test_insufficient
    params = {
      "commit_message" => "Adding",
      "type" => "file",
    }

    begin
      Payload.extract(params)

    rescue Payload::Invalid => e
      assert_equal({content: [:not_present]}, e.errors)

    else
      flunk "Expecting Payload::Invalid but got none"
    end
  end

  def test_too_many_params
    params = {
      "commit_message" => "Adding",
      "type" => "file",
      "content" => "",
      "unknown_key" => "val"
    }

    begin
      Payload.extract(params)
    rescue => err
      assert err.kind_of?(Payload::Invalid)
      assert_equal({ "unknown_key" => [:not_valid]}, err.errors)
    end
  end
end
