namespace :properties do
  desc "Télécharge et attache les images pour tous les biens qui ont des image_urls stockées"
  task download_images: :environment do
    properties = Property.where.not(image_urls: [nil, ""])

    puts "#{properties.count} bien(s) avec des image_urls à traiter..."

    properties.each do |property|
      puts "  → Bien ##{property.id} : #{property.title}"
      DownloadPropertyImagesJob.perform_later(property.id)
    end

    puts "Jobs en file d'attente. Les images seront téléchargées en arrière-plan."
  end
end

