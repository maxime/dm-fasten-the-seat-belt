require 'tempfile' 
require 'mini_magick'

require File.dirname(__FILE__) + '/../spec_helper'

describe DataMapper::FastenTheSeatBelt, "outside of Merb" do
  before :all do
    @children_original_file_path = File.dirname(__FILE__) + '/files/children.jpg'
    @children_tempfile = Tempfile.new('children.jpg')
    FileUtils.copy(@children_original_file_path, @children_tempfile.path)
    
    @children_picture = Picture.new(:file => {:filename => 'children.jpg',
                                             :content_type => 'image/jpeg',
                                             :tempfile => @children_tempfile})
    # Expected file paths
    @main_file_path = File.join(File.dirname(__FILE__), 'storage', 'pictures', '0000', '0001', 'children.jpg')
    @large_thumbnail_file_path = File.join(File.dirname(__FILE__), 'storage', 'pictures', '0000', '0001', 'children_large.jpg')
    @small_thumbnail_file_path = File.join(File.dirname(__FILE__), 'storage', 'pictures', '0000', '0001', 'children_small.jpg')
  end
  
  after :all do
    @children_tempfile.close!
  end
  
  it "should be able to attach pictures" do
    @children_picture.should be_valid
    @children_picture.save.should == true
  end
  
  it "should create the pictures in the file system with the right dimensions and the right path" do
    # original file
    File.exists?(@main_file_path).should == true
    File.size(@main_file_path).should == File.size(@children_original_file_path)

    # thumbnails

    # large thumbnail
    File.exists?(@large_thumbnail_file_path).should == true
    large_thumbnail = MiniMagick::Image.from_file(@large_thumbnail_file_path)
    large_thumbnail[:width].should == 800
    large_thumbnail[:height].should == 533

    # small thumbnail
    File.exists?(@small_thumbnail_file_path).should == true
    small_thumbnail = MiniMagick::Image.from_file(@small_thumbnail_file_path)
    small_thumbnail[:width].should == 232
    small_thumbnail[:height].should == 232
  end
    
  it "should be able to recreate the thumbnails of the pictures" do
    File.delete(@large_thumbnail_file_path)
    File.delete(@small_thumbnail_file_path)
    
    File.exists?(@large_thumbnail_file_path).should == false
    File.exists?(@small_thumbnail_file_path).should == false

    Picture.recreate_thumbnails!
    
    File.exists?(@large_thumbnail_file_path).should == true
    File.exists?(@small_thumbnail_file_path).should == true    
  end
  
  it "should be able to get the image and thumbnail absolute paths" do
    File.expand_path(@children_picture.absolute_path).should == @main_file_path
    File.expand_path(@children_picture.absolute_path(:small)).should == @small_thumbnail_file_path
    File.expand_path(@children_picture.absolute_path(:large)).should == @large_thumbnail_file_path
  end
  
  it "should support delayed compression" do
    new_picture_tempfile = Tempfile.new('children.jpg')
    FileUtils.copy(@children_original_file_path, new_picture_tempfile.path)
    
    new_picture = Picture.new(:file => {:filename => 'children.jpg',
                                             :content_type => 'image/jpeg',
                                             :tempfile => new_picture_tempfile})
    new_picture.dont_compress_now!
    new_picture.save
    
    new_picture.reload
    
    # Image shouldn't be compressed yet
    new_picture.images_are_compressed.should == false
    
    size_before_compression = File.size(new_picture.absolute_path(:large))
    
    # Compress now
    new_picture.compress_now!
    new_picture.reload
    
    size_after_compression = File.size(new_picture.absolute_path(:large))
    
    # Compressed image should be smaller in size
    size_before_compression.should > size_after_compression
    
    # Image should be marked as compressed
    new_picture.images_are_compressed.should == true    
  end
  
  it "should be able to delete the files if the object is destroyed" do
    @children_picture.destroy
    File.exists?(@main_file_path).should == false
    
    File.exists?(@large_thumbnail_file_path).should == false
    
    File.exists?(@small_thumbnail_file_path).should == false
  end
  
  it "should raise an error if it's not running in Merb and if the file_system_path isn't present" do
    lambda {
      class BrokenPicture
        include DataMapper::Resource
        include DataMapper::FastenTheSeatBelt

        property :id, Serial
        fasten_the_seat_belt
      end
    }.should raise_error("If you're running dm-fasten-the-seat-belt outside of Merb, you must specifiy :file_system_path in the options")

  end
end

describe DataMapper::FastenTheSeatBelt, "inside Merb" do
  before :all do
    module Merb
      def self.root
        File.join(File.dirname(__FILE__), 'merb')
      end
      
      def self.env
        "production"
      end
    end
    
    class Image
      include DataMapper::Resource
      include DataMapper::FastenTheSeatBelt

      property :id, Serial

      fasten_the_seat_belt :thumbnails => {:small => {:size => "320x240", :quality => 99}}
    end
    
    Image.auto_migrate!
    
    @sunshine_original_file_path = File.dirname(__FILE__) + '/files/sunshine.jpg'
    @sunshine_tempfile = Tempfile.new('sunshine.jpg')
    FileUtils.copy(@sunshine_original_file_path, @sunshine_tempfile.path)
    
    @sunshine_image = Image.new(:file => {:filename => 'sunshine.jpg',
                                             :content_type => 'image/jpeg',
                                             :tempfile => @sunshine_tempfile})
    # Expected file paths
    @main_file_path = File.join(File.dirname(__FILE__), 'merb', 'public', 'production', 'images', '0000', '0001', 'sunshine.jpg')
    @small_thumbnail_file_path = File.join(File.dirname(__FILE__), 'merb', 'public', 'production', 'images', '0000', '0001', 'sunshine_small.jpg')
  end
  
  after :all do
    @sunshine_tempfile.close!
  end
  
  it "should be able to attach images" do
    @sunshine_image.save.should == true
  end
  
  it "should store the files under the public/production/images directory by default" do
    File.expand_path(@sunshine_image.absolute_path).should == @main_file_path
    File.expand_path(@sunshine_image.absolute_path(:small)).should == @small_thumbnail_file_path     
  end
  
  it "should be able to return the web path" do
    @sunshine_image.path.should == '/production/images/0000/0001/sunshine.jpg'
    @sunshine_image.path(:small).should == '/production/images/0000/0001/sunshine_small.jpg'
  end
  
  it "should raise an error if we try to get a web path and if the pictures aren't in the public directory" do
    class Image
      fasten_the_seat_belt :thumbnails => {:small => {:size => "320x240", :quality => 99}}, :file_system_path => (File.dirname(__FILE__) + '/storage/images2')
    end
    
    lambda { @sunshine_image.path }.should raise_error("Can't return web directory name, the images aren't stored under the Merb application public directory")
  end
  
  it "should output 'Quality not supported' if we try to apply a quality setting on a non-jpeg image" do
    @png_original_file_path = File.dirname(__FILE__) + '/files/children.png'
    @png_tempfile = Tempfile.new('children.png')
    FileUtils.copy(@png_original_file_path, @png_tempfile.path)
    
    @png_image = Image.new(:file => {:filename => 'children.png',
                                     :content_type => 'image/png',
                                     :tempfile => @png_tempfile})
    @png_image.should_receive(:puts).with("FastenTheSeatBelt says: Quality setting not supported for image/png files")
    @png_image.save
  end
end
