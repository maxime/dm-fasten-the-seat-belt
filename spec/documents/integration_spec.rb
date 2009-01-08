require 'tempfile' 

require File.dirname(__FILE__) + '/../spec_helper'

describe DataMapper::FastenTheSeatBelt, "outside of Merb" do
  before :all do
    @pdf_original_file_path = File.dirname(__FILE__) + '/files/document.pdf'
    @pdf_tempfile = Tempfile.new('document.pdf')
    FileUtils.copy(@pdf_original_file_path, @pdf_tempfile.path)
    
    @pdf = Document.new(:file => {:filename => 'document.pdf',
                                  :content_type => 'application/pdf',
                                  :tempfile => @pdf_tempfile})
    # Expected file paths
    @main_file_path = File.join(File.dirname(__FILE__), 'storage', 'documents', '0000', '0001', 'document.pdf')
  end
  
  after :all do
    @pdf_tempfile.close!
  end
  
  it "should be able to attach pdf documents" do
    @pdf.should be_valid
    @pdf.save.should == true
  end
  
  it "should be able to save the document file in the right place" do
    File.exists?(@main_file_path).should == true
  end
  
  it "should be able to return the path of a document" do
    File.expand_path(@pdf.absolute_path).should == @main_file_path
  end
  
  it "should be able to delete the files if the object is destroyed" do
    @pdf.destroy
    File.exists?(@main_file_path).should == false
  end
end