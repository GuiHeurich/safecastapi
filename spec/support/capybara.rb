# frozen_string_literal: true

Capybara.configure do |config|
  config.match = :prefer_exact
  config.ignore_hidden_elements = false
end
