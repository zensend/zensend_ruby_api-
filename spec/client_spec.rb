require 'spec_helper'

describe ZenSend do

  SMS_URL = "https://api.zensend.io/v3/sendsms"
  KEYWORDS_URL = "https://api.zensend.io/v3/keywords"

  CHECK_BALANCE_URL = "https://api.zensend.io/v3/checkbalance"

  PRICES_URL = "https://api.zensend.io/v3/prices"
  OPERATOR_LOOKUP_URL = "https://api.zensend.io/v3/operator_lookup"

  before(:each) do
    @client = ZenSend::Client.new("API_KEY")
  end

  it "should be able to create a keyword" do

    stub_request(:post, KEYWORDS_URL).
      to_return(:headers => {'Content-Type' => "application/json"}, :body => '{
      "success": {
          "cost_in_pence": 5.4,
          "new_balance_in_pence": 10.2
      }
    }')

    

    result = @client.create_keyword(shortcode: "SC", keyword: "KW")

    expect(result.cost_in_pence).to eq(5.4)
    expect(result.new_balance_in_pence).to eq(10.2)

    expect(WebMock).to have_requested(:post, KEYWORDS_URL).
      with(:body => "SHORTCODE=SC&KEYWORD=KW", :headers => {'X-API-KEY' => "API_KEY"})

  end

  it "should be able to create a keyword with options" do

    stub_request(:post, KEYWORDS_URL).
      to_return(:headers => {'Content-Type' => "application/json"}, :body => '{
      "success": {
          "cost_in_pence": 5.4,
          "new_balance_in_pence": 10.2
      }
    }')

    

    result = @client.create_keyword(shortcode: "SC", keyword: "KW", is_sticky: true, mo_url: "http://mo")

    expect(result.cost_in_pence).to eq(5.4)
    expect(result.new_balance_in_pence).to eq(10.2)

    expect(WebMock).to have_requested(:post, KEYWORDS_URL).
      with(:body => "SHORTCODE=SC&KEYWORD=KW&IS_STICKY=true&MO_URL=http%3A%2F%2Fmo", :headers => {'X-API-KEY' => "API_KEY"})

  end

  it "should be able to send an sms" do

    stub_request(:post, SMS_URL).
      to_return(:headers => {'Content-Type' => "application/json"}, :body => '{
      "success": {
          "txguid": "7CDEB38F-4370-18FD-D7CE-329F21B99209",
          "numbers": 1,
          "smsparts": 1,
          "encoding": "gsm",
          "cost_in_pence": 5.4,
          "new_balance_in_pence": 10.2
      }
    }')

    

    result = @client.send_sms(originator: "ORIG", body: "BODY", numbers: ["447796354848"])

    expect(result.numbers).to eq(1)
    expect(result.sms_parts).to eq(1)
    expect(result.encoding).to eq("gsm")
    expect(result.tx_guid).to eq("7CDEB38F-4370-18FD-D7CE-329F21B99209")
    expect(result.cost_in_pence).to eq(5.4)
    expect(result.new_balance_in_pence).to eq(10.2)

    expect(WebMock).to have_requested(:post, SMS_URL).
      with(:body => "ORIGINATOR=ORIG&BODY=BODY&NUMBERS=447796354848", :headers => {'X-API-KEY' => "API_KEY"})

  end



  it "should be able to send an sms with the optional parameters" do

    stub_request(:post, SMS_URL).
      to_return(:headers => {'Content-Type' => "application/json"}, :body => '{
      "success": {
          "txguid": "7CDEB38F-4370-18FD-D7CE-329F21B99209",
          "numbers": 1,
          "smsparts": 1,
          "encoding": "gsm",
          "cost_in_pence": 5.4,
          "new_balance_in_pence":10.2
      }
    }')

    result = @client.send_sms(originator: "ORIG", body: "BODY", numbers: ["447796354848"], originator_type: :alpha, encoding: :gsm, timetolive_in_minutes: 60)

    expect(WebMock).to have_requested(:post, SMS_URL).
      with(:body => "ORIGINATOR=ORIG&BODY=BODY&NUMBERS=447796354848&ORIGINATOR_TYPE=alpha&TIMETOLIVE=60&ENCODING=gsm", :headers => {'X-API-KEY' => "API_KEY"})

  end


  it "should be able to send multiple smses" do

    stub_request(:post, SMS_URL).
      to_return(:headers => {'Content-Type' => "application/json"}, :body => '{
      "success": {
          "txguid": "7CDEB38F-4370-18FD-D7CE-329F21B99209",
          "numbers": 2,
          "smsparts": 1,
          "encoding": "gsm",
          "cost_in_pence": 5.4,
          "new_balance_in_pence":10.2
      }
    }')

    

    @client.send_sms(originator: "ORIG", body: "BODY", numbers: ["447796354848", "447796354849"])


    expect(WebMock).to have_requested(:post, SMS_URL).
      with(:body => "ORIGINATOR=ORIG&BODY=BODY&NUMBERS=447796354848%2C447796354849", :headers => {'X-API-KEY' => "API_KEY"})

  end



  it "should not be able to put a , in the numbers array" do



    

    expect {@client.send_sms(originator: "ORIG", body: "BODY", numbers: ["44779635484,8", "447796354849"])}
      .to raise_error(ArgumentError)


   
  end

  it "should generate an error if an unknown parameter is included" do



    

    expect {@client.send_sms(originator: "ORIG", body: "BODY", timetolive: "128", numbers:["447796354848"])}
      .to raise_error(ArgumentError)


   
  end


  it "should be able to handle an error" do

    stub_request(:post, SMS_URL).
      to_return(:status => 400, :headers => {'Content-Type' => "application/json"}, :body => '{
      "failure": {
          "failcode": "GENERIC_ERROR"
      }
    }')



    expect {
      @client.send_sms(originator: "ORIG", body: "BODY", numbers: ["447796354848"])
    }.to raise_error do |error|
      expect(error).to be_a(ZenSend::ZenSendException)
      expect(error.failcode).to eq("GENERIC_ERROR")
      expect(error.http_code).to eq("400")
      expect(error.parameter).to eq(nil)
    end

  end


  it "should be able to handle a parameter error" do

    stub_request(:post, SMS_URL).
      to_return(:status => 400, :headers => {'Content-Type' => "application/json"}, :body => '{
      "failure": {
          "failcode": "IS_EMPTY",
          "parameter": "BODY"
      }
    }')



    expect {
      @client.send_sms(originator: "ORIG", body: "BODY", numbers: ["447796354848"])
    }.to raise_error do |error|
      expect(error).to be_a(ZenSend::ZenSendException)
      expect(error.failcode).to eq("IS_EMPTY")
      expect(error.http_code).to eq("400")
      expect(error.parameter).to eq("BODY")
    end

  end


  it "should be able to handle a non-json response" do

    stub_request(:post, SMS_URL).
      to_return(:status => 503, :headers => {'Content-Type' => "text/plain"}, :body => 'Gateway Timeout')



    expect {
      @client.send_sms(originator: "ORIG", body: "BODY", numbers: ["447796354848"])
    }.to raise_error do |error|
      expect(error).to be_a(ZenSend::ZenSendException)
      expect(error.failcode).to eq(nil)
      expect(error.http_code).to eq("503")
      expect(error.parameter).to eq(nil)
    end

  end

  it "should be able to handle an invalid json response" do

    stub_request(:post, SMS_URL).
      to_return(:status => 400, :headers => {'Content-Type' => "application/json"}, :body => '{
      "failures": {
          "failcode": "IS_EMPTY",
          "parameter": "BODY"
      }
    }')



    expect {
      @client.send_sms(originator: "ORIG", body: "BODY", numbers: ["447796354848"])
    }.to raise_error do |error|
      expect(error).to be_a(ZenSend::ZenSendException)
      expect(error.failcode).to eq(nil)
      expect(error.http_code).to eq("400")
      expect(error.parameter).to eq(nil)
    end

  end

  it "should be able to retrieve the balance" do

    stub_request(:get, CHECK_BALANCE_URL).
      to_return(:headers => {'Content-Type' => "application/json"}, :body => '{
      "success": {
          "balance": 100.2
      }
    }')


    balance = @client.check_balance

    expect(balance).to eq(100.2)

  end

  it "should be able to retrieve the prices" do

    stub_request(:get, PRICES_URL).
      to_return(:headers => {'Content-Type' => "application/json"}, :body => '{
      "success": {
          "prices_in_pence": {"GB":1.23,"US":1.24}
      }
    }')


    prices = @client.get_prices

    expect(prices).to eq({"GB" => 1.23, "US" => 1.24})

  end

  it "should be able to do an operator lookup" do
    stub_request(:get, OPERATOR_LOOKUP_URL + "?NUMBER=441234567890").
      to_return(:headers => {'Content-Type' => "application/json"}, :body => '{
        "success": {
          "mnc":"123",
          "mcc":"456",
          "operator":"o2-uk",
          "cost_in_pence":2.5,
          "new_balance_in_pence":100.0
        }
      }')

    result = @client.lookup_operator("441234567890")
    expect(result.mnc).to eq("123")
    expect(result.mcc).to eq("456")
    expect(result.operator).to eq("o2-uk")
    expect(result.cost_in_pence).to eq(2.5)
    expect(result.new_balance_in_pence).to eq(100.0)
  end

  it "should be able to handle an error from an operator lookup" do
    stub_request(:get, OPERATOR_LOOKUP_URL + "?NUMBER=441234567890").
      to_return(:status => 503, :headers => {'Content-Type' => "application/json"}, :body => '{
        "failure": {
          "failcode":"DATA_MISSING",
          "cost_in_pence":2.5,
          "new_balance_in_pence":100.0
        }
      }')


    expect {
      @client.lookup_operator("441234567890")
    }.to raise_error do |error|
      expect(error.http_code).to eq("503")
      expect(error.failcode).to eq("DATA_MISSING")
      expect(error.cost_in_pence).to eq(2.5)
      expect(error.new_balance_in_pence).to eq(100.0)
    end


  end

end
