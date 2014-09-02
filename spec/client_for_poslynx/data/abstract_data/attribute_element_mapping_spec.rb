# coding: utf-8

require 'spec_helper'

describe ClientForPoslynx::Data::AbstractData::AttributeElementMapping do

  it "Fails creation without :attribute option" do
    expect{
      described_class.new element: 'Foo'
    }.to raise_exception( ArgumentError )
  end

  it "Fails creation without :element option" do
    expect{
      described_class.new attribute: :foo
    }.to raise_exception( ArgumentError )
  end

  it "Creates a text mapping instance with minimum attriubtes" do
    actual = described_class.new(
      attribute: :foo, element: 'Foo'
    )
    expect( actual ).to be_text_mapping
  end

  it "Creates a multi-text mapping instance with multi_text attribute" do
    actual = described_class.new(
      attribute: :foo, element: 'Foo', multi_text: true
    )
    expect( actual ).to be_multi_text_mapping
  end

  it "Creates a numbered_lines mapping instance with numbered_lines attribute" do
    actual = described_class.new(
      attribute: :foo, element: 'Foo', numbered_lines: 'the-template'
    )
    expect( actual ).to be_numbered_lines_mapping
  end

  it "Fails creation with unexpected attribute" do
    expect{
      described_class.new attribute: :foo, element: 'Foo', bar: true
    }.to raise_exception( ArgumentError )
  end

  it "fails creation with both nulti-text and numbered-lines options" do
    expect{
      described_class.new attribute: :foo, element: 'Foo', multi_text: true, numbered_lines: 'x'
    }.to raise_exception( ArgumentError )
  end

end
