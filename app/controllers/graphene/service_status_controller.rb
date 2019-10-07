# frozen_string_literal: true

class ServiceStatusController < ApplicationController
  # rubocop:disable Metrics/MethodLength
  def status
    body = <<~HTML.html_safe
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <title>Status</title>
        </head>
        <body>
          <h2>[#{Time.now}] Chimera is Alive!</h2>
          <h2>Chimera Options</h2>
          <ul>
            <li>
              <a href="#{sidekiq_web_path}">Sidekiq</a>
              <a href="#{ui_pipelines_path}">Pipeline UI</a>
            </li>
          </ul>
        </body>
      </html>
    HTML

    render(html: body)
  end
  # rubocop:enable Metrics/MethodLength
end
