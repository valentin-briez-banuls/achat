#!/usr/bin/env ruby
# Test de l'extraction d'images

puts "=" * 80
puts "TEST D'EXTRACTION D'IMAGES"
puts "=" * 80
puts

# HTML de test avec des images
html_test = <<~HTML
  <html>
    <head>
      <meta property="og:image" content="https://example.com/image1.jpg">
      <script type="application/ld+json">
      {
        "@type": "Product",
        "image": ["https://example.com/image2.jpg", "https://example.com/image3.jpg"]
      }
      </script>
    </head>
    <body>
      <img src="https://example.com/photo1.jpg" class="property-image">
      <img src="https://example.com/photo2.jpg" class="gallery-image">
    </body>
  </html>
HTML

url = "https://example.com/annonce"

puts "Test 1 : Extraction depuis HTML"
extractor = PropertyImageExtractorService.new(html_test, url)
images = extractor.call

puts "  Images trouvées : #{images.size}"
images.each_with_index do |img, i|
  puts "    #{i+1}. #{img}"
end

if extractor.errors.any?
  puts "  Erreurs :"
  extractor.errors.each { |e| puts "    - #{e}" }
end
puts

# Test 2 : Via le scraper
puts "Test 2 : Via PropertyScraperService"
scraper = PropertyScraperService.new(url, images: true, cache: false)

# Simuler un fetch
puts "  Option images activée : #{scraper.instance_variable_get(:@extract_images)}"
puts "  Array image_urls initialisé : #{scraper.image_urls.class}"
puts

puts "=" * 80

