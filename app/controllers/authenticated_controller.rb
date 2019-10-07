# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  RSA_PUBLIC = OpenSSL::PKey::RSA.new(Base64.decode64(ENV["JWT_RSA_PUBLIC"]))

  JWT_OPTIONS = {
    algorithm: ENV["JWT_ALGORITHM"],
    iss: ENV["JWT_ISSUER"],
    verify_iss: true,
    verify_iat: true
  }.freeze

  JWT_ERRORS = {
    JWT::ExpiredSignature => {
      status: 403, body: "The token has expired."
    },
    JWT::InvalidIssuerError => {
      status: 403, body: "The token does not have a valid issuer."
    },
    JWT::InvalidIatError => {
      status: 403, body: "The token does not have a valid 'issued at' time."
    },
    JWT::DecodeError => {
      status: 401, body: "A valid token must be passed."
    },
    KeyError => {
      status: 401, body: "HTTP_AUTHORIZATION header must be present."
    }
  }.freeze

  before_action :check_jwt_auth_token!

  private

  def check_jwt_auth_token!
    auth_token = request.headers.fetch("HTTP_AUTHORIZATION").gsub(/bearer /i, "")
    _payload, _header = JWT.decode(auth_token, RSA_PUBLIC, true, JWT_OPTIONS)
  rescue StandardError => e
    render(JWT_ERRORS.fetch(e.class) { raise e })
  end
end
