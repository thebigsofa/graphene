# frozen_string_literal: true

RSpec.shared_context :with_auth_token do
  let(:time_now) { Time.now.to_i }
  let(:exp) { time_now + 7200 }
  let(:iss) { ENV["JWT_ISSUER"] }
  let(:iat) { time_now }

  let(:auth_payload) do
    {
      iss: iss,
      exp: exp,
      iat: iat
    }
  end

  let(:auth_token) do
    JWT.encode(
      auth_payload,
      OpenSSL::PKey::RSA.new(Base64.decode64(ENV["JWT_RSA_PRIVATE"])),
      ENV["JWT_ALGORITHM"]
    )
  end

  let(:headers) do
    {
      "CONTENT_TYPE" => "application/json",
      "HTTP_AUTHORIZATION" => "Bearer #{auth_token}"
    }
  end
end
