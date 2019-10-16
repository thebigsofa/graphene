# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::ServiceStatusController, type: :controller do
  describe "GET /status" do
    before { get :status }

    it "responds with 200" do
      expect(response.status).to eq(200)
    end
  end
end
