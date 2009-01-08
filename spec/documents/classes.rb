class Document
  include DataMapper::Resource
  include DataMapper::FastenTheSeatBelt
  
  property :id, Serial
  
  fasten_the_seat_belt :file_system_path => File.dirname(__FILE__) + '/storage/documents'

  validates_present :file, :if => Proc.new{|resource| resource.new_record?}
end
