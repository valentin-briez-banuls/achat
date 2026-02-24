class JavascriptRendererService
  attr_reader :errors

  def initialize(url)
    @url = url
    @errors = []
  end

  def call
    return nil unless ferrum_available?

    Rails.logger.info("JavascriptRendererService: Rendering #{@url}")

    browser = Ferrum::Browser.new(headless: true, timeout: 30)

    begin
      browser.go_to(@url)
      sleep 2
      browser.at_xpath("//body")
      html = browser.body
      Rails.logger.info("JavascriptRendererService: Success (#{html.bytesize} bytes)")
      html
    rescue StandardError => e
      @errors << "Erreur rendu JS : #{e.message}"
      Rails.logger.error("JavascriptRendererService error: #{e.message}")
      nil
    ensure
      browser&.quit
    end
  end

  def self.enabled?
    require "ferrum"
    true
  rescue LoadError
    false
  end

  private

  def ferrum_available?
    self.class.enabled?
  end
end

