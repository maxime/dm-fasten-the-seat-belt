class Picture
  include DataMapper::Resource
  include DataMapper::FastenTheSeatBelt
  
  property :id, Serial
  
  fasten_the_seat_belt :thumbnails => {
                                        :small => {:size => "232x232", :crop => true, :quality => 100},
                                        :large => {:size => "800x600", :quality => 90},
                                      },
                       :file_system_path => File.dirname(__FILE__) + '/storage/pictures'

  validates_present :file, :if => Proc.new{|resource| resource.new_record?}
end
