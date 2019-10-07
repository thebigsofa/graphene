# frozen_string_literal: true

RSpec.describe AuthenticatedController, :with_auth_token, type: :controller do
  controller AuthenticatedController do
    def create
      head(:created)
    end
  end

  let(:headers) do
    {
      "CONTENT_TYPE" => "application/json",
      "HTTP_AUTHORIZATION" => "Bearer #{auth_token}"
    }
  end

  before do
    request.headers.merge!(headers)
    post :create, params: {}
  end

  subject do
    response
  end

  context "when signature is expired" do
    let(:exp) { Time.now.to_i - 100 }

    its(:status) { is_expected.to eq(403) }
    its(:body) { is_expected.to eq("The token has expired.") }
  end

  context "when issuer is invalid" do
    let(:iss) { ENV["JWT_ISSUER"] + "_some_fake_stuff" }

    its(:status) { is_expected.to eq(403) }
    its(:body) { is_expected.to eq("The token does not have a valid issuer.") }
  end

  context "when issuer is not present in the headers" do
    let(:auth_payload) do
      {
        exp: exp,
        iat: iat
      }
    end

    its(:status) { is_expected.to eq(403) }
    its(:body) { is_expected.to eq("The token does not have a valid issuer.") }
  end

  context "when issued at is invalid" do
    let(:iat) { "sdfsdfsdfsdf" }

    its(:status) { is_expected.to eq(403) }
    its(:body) { is_expected.to eq("The token does not have a valid 'issued at' time.") }
  end

  context "when token is invalid" do
    let(:headers) do
      {
        "CONTENT_TYPE" => "application/json",
        "HTTP_AUTHORIZATION" => "Bearer NOT_VALID_TOKEN"
      }
    end

    its(:status) { is_expected.to eq(401) }
    its(:body) { is_expected.to eq("A valid token must be passed.") }
  end

  context "when token is not present" do
    let(:headers) do
      {
        "CONTENT_TYPE" => "application/json"
      }
    end

    its(:status) { is_expected.to eq(401) }
    its(:body) { is_expected.to eq("HTTP_AUTHORIZATION header must be present.") }
  end
end
