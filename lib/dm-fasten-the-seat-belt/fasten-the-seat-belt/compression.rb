module DataMapper
  module FastenTheSeatBelt
    module Compression
      COMPRESSABLE_MIME_TYPES = ["image/jpeg", "image/jpg", "image/pjpeg"]
      
      def compressable?
        COMPRESSABLE_MIME_TYPES.include?(self.content_type)
      end
      
      def dont_compress_now!
        self.images_are_compressed = false
      end

      def compress_jpeg(filename, quality)
        if compressable?
          system("jpegoptim -m#{quality} -q --strip-all \"#{filename}\" &> /dev/null")
        else
          puts "FastenTheSeatBelt says: Quality setting not supported for #{self.content_type} files"
        end
      end

      def compress_now!
        return false if self.images_are_compressed
        self.class.fasten_the_seat_belt_options[:thumbnails].each_pair do |key, value|
          thumb_filename = absolute_path(key)

          compress_jpeg(thumb_filename, value[:quality].to_i) if value[:quality] and value[:quality].to_i < 100
        end

        self.update_attributes(:images_are_compressed => true)
      end
      
    end # Compression
  end # FastenTheSeatBelt
end # DataMapper