# -*- encoding: utf-8 -*-

describe :stringio_write, :shared => true do
  before(:each) do
    @io = StringIO.new('12345')
  end

  it "tries to convert the passed Object to a String using #to_s" do
    obj = mock("to_s")
    obj.should_receive(:to_s).and_return("to_s")
    @io.send(@method, obj)
    @io.string.should == "to_s5"
  end

  it "raises an IOError if the data String is frozen after creating the StringIO instance" do
    s = "abcdef"
    io = StringIO.new s, "w"
    s.freeze
    lambda { io.write "xyz" }.should raise_error(IOError)
  end
end

describe :stringio_write_string, :shared => true do
  before(:each) do
    @io = StringIO.new('12345')
  end

  # TODO: RDoc says that #write appends at the current position.
  it "writes the passed String at the current buffer position" do
    @io.pos = 2
    @io.send(@method, 'x').should == 1
    @io.string.should == '12x45'
    @io.send(@method, 7).should == 1
    @io.string.should == '12x75'
  end

  it "pads self with \\000 when the current position is after the end" do
    @io.pos = 8
    @io.send(@method, 'x')
    @io.string.should == "12345\000\000\000x"
    @io.send(@method, 9)
    @io.string.should == "12345\000\000\000x9"
  end

  it "returns the number of bytes written" do
    @io.send(@method, '').should == 0
    @io.send(@method, nil).should == 0
    str = "1" * 100
    @io.send(@method, str).should == 100
  end

  it "updates self's position" do
    @io.send(@method, 'test')
    @io.pos.should eql(4)
  end

  it "taints self's String when the passed argument is tainted" do
    @io.send(@method, "test".taint)
    @io.string.tainted?.should be_true
  end

  it "does not taint self when the passed argument is tainted" do
    @io.send(@method, "test".taint)
    @io.tainted?.should be_false
  end


  with_feature :encoding do

    before :each do
      @enc_io = StringIO.new("Hëllø")
    end

    it "writes binary data into the io" do
      data = "Hëll\xFF"
      data.force_encoding("ASCII-8BIT")
      @enc_io.send(@method, data)
      @enc_io.string.should == "Hëll\xFF\xB8"
    end

    it "writes binary data in different encodings" do
      data = "Hëllø"
      @enc_io.send(@method, data)
      @enc_io.string.should == "Hëllø"
      data = "Hëll\xFF"
      data.force_encoding("ASCII-8BIT")
      @enc_io.send(@method, data)
      @enc_io.string.should == "HëlløHëll\xFF"
    end

    it "retains the original encoding" do
      data = "Hëll\xFF"
      data.force_encoding("ASCII-8BIT")
      @enc_io.send(@method, data)
      @enc_io.string.encoding.should == Encoding::UTF_8
    end

    it "returns the number of bytes written" do
      data = "Hëll\xFF"
      data.force_encoding("ASCII-8BIT")
      @enc_io.send(@method, data).should == 6
    end

    it "pads multibyte characters properly" do
      @enc_io.pos = 8
      @enc_io.send(@method, 'x')
      @enc_io.string.should == "Hëllø\000x"
      @enc_io.send(@method, 9)
      @enc_io.string.should == "Hëllø\000x9"
    end

  end

end

describe :stringio_write_not_writable, :shared => true do
  it "raises an IOError" do
    io = StringIO.new("test", "r")
    lambda { io.send(@method, "test") }.should raise_error(IOError)

    io = StringIO.new("test")
    io.close_write
    lambda { io.send(@method, "test") }.should raise_error(IOError)
  end
end

describe :stringio_write_append, :shared => true do
  before(:each) do
    @io = StringIO.new("example", "a")
  end

  it "appends the passed argument to the end of self" do
    @io.send(@method, ", just testing")
    @io.string.should == "example, just testing"

    @io.send(@method, " and more testing")
    @io.string.should == "example, just testing and more testing"
  end

  it "correctly updates self's position" do
    @io.send(@method, ", testing")
    @io.pos.should eql(16)
  end
end
