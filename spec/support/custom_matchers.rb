require 'rspec/expectations'
require "rexml/document"

# Use: it { should accept_nested_attributes_for(:association_name).and_accept({valid_values => true}).but_reject({ :reject_if_nil => nil })}
RSpec::Matchers.define :accept_nested_attributes_for do |association|
  match do |model|
    @model = model
    @nested_att_present = model.respond_to?("#{association}_attributes=".to_sym)
    if @nested_att_present && @reject
      model.send("#{association}_attributes=".to_sym,[@reject])
      @reject_success = model.send("#{association}").empty?
    end
    if @nested_att_present && @accept
      model.send("#{association}_attributes=".to_sym,[@accept])
      @accept_success = ! (model.send("#{association}").empty?)
    end
    @nested_att_present && ( @reject.nil? || @reject_success ) && ( @accept.nil? || @accept_success )
  end

  failure_message do
    messages = []
    messages << "expected #{@model.class} to accept nested attributes for #{association}" unless @nested_att_present
    messages << "expected #{@model.class} to reject values #{@reject.inspect} for association #{association}" unless @reject_success
    messages << "expected #{@model.class} to accept values #{@accept.inspect} for association #{association}" unless @accept_success
    messages.join(", ")
  end

  description do
    desc = "accept nested attributes for #{expected}"
    if @reject
      desc << ", but reject if attributes are #{@reject.inspect}"
    end
  end

  chain :but_reject do |reject|
    @reject = reject
  end

  chain :and_accept do |accept|
    @accept = accept
  end
end

RSpec::Matchers.define :have_rows do |rows|
  match do |export|
    @rows = rows
    doc = REXML::Document.new(open(export.file.url).read)
    @doc_rows = doc.elements.to_a('//Row').map do |r|
      r.elements.to_a('Cell/Data').map{|d| d.text }
    end
    @rows == @doc_rows
  end

  failure_message do |export|
    "Expected export to have rows:\n#{@rows}\nbut instead it had:\n#{@doc_rows}"
  end

  failure_message_when_negated do |export|
    "Expected export to NOT have rows:\n#{@rows}\nbut it did"
  end

  description do
    "have rows #{expected}"
  end
end