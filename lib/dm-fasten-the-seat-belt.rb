require 'rubygems'
require 'pathname'

require 'mini_magick'

gem 'dm-core', '1.0.0'
require 'dm-core'

require File.join(File.dirname(__FILE__), 'dm-fasten-the-seat-belt', 'fasten-the-seat-belt','compression')

module DataMapper
  module FastenTheSeatBelt
    def self.included(base)
      base.send(:extend, ClassMethods)
      base.send(:include, InstanceMethods)
      base.send(:include, Compression)      
      base.send(:include, MiniMagick)
      base.class_eval do
        attr_accessor :file
    
        class << self; attr_accessor :fasten_the_seat_belt_options end
        
        @fasten_the_seat_belt_options
      end
    end
  
    module ClassMethods

      def fasten_the_seat_belt(options={})
        # Properties
        self.property :filename, String
        self.property :size, Integer, :lazy => true
        self.property :content_type, String, :lazy => true
        self.property :created_at, DateTime, :lazy => true
        self.property :updated_at, DateTime, :lazy => true
    
        self.property :images_are_compressed, DataMapper::Types::Boolean, :lazy => true
    
        # Callbacks to manage the file
        before :save, :save_attributes
        after :save, :save_file
        after :destroy, :delete_directory
      
        # Options
        if !defined?(Merb) && !options[:file_system_path]
          raise "If you're running dm-fasten-the-seat-belt outside of Merb, you must specifiy :file_system_path in the options"
        end
        
        options[:file_system_path] ||= File.join((defined?(Merb) ? Merb.root : ''), 'public', merb_environment, self.storage_name)
        options[:thumbnails] ||= {}
    
        self.fasten_the_seat_belt_options = options
      end
    
      def recreate_thumbnails!
        all.each {|object| object.generate_thumbnails! }
        true
      end
      
      def merb_environment
        (defined?(Merb) ? Merb.env : '')
      end
    end
  
    module InstanceMethods
    
      # Get file path
      #
      def path(thumb=nil)
        File.join(web_directory_name, filename_for_thumbnail(thumb))
      end  
            
      def absolute_path(thumb=nil)
        File.join(complete_directory_name, filename_for_thumbnail(thumb))
      end
      
      def filename_for_thumbnail(thumb=nil)
        if thumb != nil
          basename = self.filename.gsub(/\.(.*)$/, '')
          extension = self.filename.gsub(/^(.*)\./, '')
          return basename + '_' + thumb.to_s + '.' + extension
        else
          return self.filename
        end
      end
            
      def save_attributes
        return unless @file
        # The following line is solving an IE6 problem. This removes the C:\Documents and Settings\.. shit
        @file[:filename] = File.basename(@file[:filename].gsub(/\\/, '/')) if @file[:filename]
      
        # Setup attributes
        [:content_type, :size, :filename].each do |attribute|
          self.send("#{attribute}=", @file[attribute])
        end
      end

      def save_file
        return unless self.filename and @file
      
        create_directory

        FileUtils.mv @file[:tempfile].path, complete_file_path if File.exists?(@file[:tempfile].path)
      
        generate_thumbnails!
      
        @file = nil
      
        # By default, images are supposed to be compressed
        self.images_are_compressed ||= true 
      end
    
      def directory_name
        # you can thank Jamis Buck for this: http://www.37signals.com/svn/archives2/id_partitioning.php
        dir = ("%08d" % self.id).scan(/..../)
        File.join(dir[0], dir[1])
      end
    
      def web_directory_name
        raise "Can't return web directory name if not running in Merb" unless defined?(Merb)
        unless complete_directory_name.include?(Merb.root)
          raise "Can't return web directory name, the images aren't stored under the Merb application public directory" 
        end
        
        complete_directory_name.gsub(/^#{Merb.root}\/public/, '')
      end
    
      def complete_directory_name
        File.join(self.class.fasten_the_seat_belt_options[:file_system_path], directory_name)
      end
  
      def complete_file_path
        File.join(complete_directory_name, (self.filename || ""))
      end

      def create_directory
        FileUtils.mkdir_p(complete_directory_name) unless FileTest.exists?(complete_directory_name)
      end

      def delete_directory 
        FileUtils.rm_rf(complete_directory_name) if FileTest.exists?(complete_directory_name)
      end

      def generate_thumbnails!
        self.class.fasten_the_seat_belt_options[:thumbnails].each_pair do |key, value|
          resize_to = value[:size]
          quality = value[:quality].to_i
        
          image = MiniMagick::Image.from_file(complete_file_path)
          if value[:crop]
            # tw, th are target width and target height
          
            tw = resize_to.gsub(/([0-9]*)x([0-9]*)/, '\1').to_i
            th = resize_to.gsub(/([0-9]*)x([0-9]*)/, '\2').to_i
          
            # ow and oh are origin width and origin height
            ow = image[:width]
            oh = image[:height]
            
            # iw and ih and the dimensions of the cropped picture before resizing
            # there are 2 cases, iw = ow or ih = oh
            # using iw / ih = tw / th, we can determine the other values
            # we use the minimal values to determine the good case
            iw = [ow, ((oh.to_f*tw.to_f) / th.to_f)].min
            ih = [oh, ((ow.to_f*th.to_f) / tw.to_f)].min
          
            # we calculate how much image we must crop
            shave_width = ((ow.to_f - iw.to_f) / 2.0).to_i
            shave_height = ((oh.to_f - ih.to_f) / 2.0).to_i
          
  
            # specify the width of the region to be removed from both sides of the image and the height of the regions to be removed from top and bottom.
            image.shave "#{shave_width}x#{shave_height}"

            # resize of the pic
            image.resize resize_to.to_s + "!"
          else
            # no cropping
            image.resize resize_to
          end
          basename = self.filename.gsub(/\.(.*)$/, '')
          extension = self.filename.gsub(/^(.*)\./, '')

          thumb_filename = File.join(complete_directory_name, (basename + '_' + key.to_s + '.' + extension))

          # Delete thumbnail if exists
          File.delete(thumb_filename) if File.exists?(thumb_filename)
          image.write thumb_filename

          next if self.images_are_compressed == false
          
          if quality and quality!=0 and quality < 100
            compress_jpeg(thumb_filename, quality)
          end
        end
      end
    end
  end # FastenTheSeatBelt
end # DataMapper