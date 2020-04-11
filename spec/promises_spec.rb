# frozen_string_literal: true

RSpec.describe Promises do
  it 'has a version number' do
    expect(Promises::VERSION).not_to be nil
  end
end

RSpec.describe Promise do
  it 'is initially pending' do
    expect(Promise.new {sleep}).to be_pending
  end

  it 'it raises error on rejects' do
    expect do
      Promise.new {|_, reject| reject.call 'hello'}.await
    end.to raise_error 'hello'
  end

  it 'is fulfilled on ::resolve' do
    expect(Promise.resolve('value')).to be_fulfilled
  end

  it 'is rejected on ::reject' do
    expect(Promise.reject('reason')).to be_rejected
  end

  describe "#then" do
    it "calls first method if the promise is fulfilled" do
      expect(Promise.resolve("some text").then {"some other text"}.await).to eq "some other text"
    end
    it "does not call first method if the promise if rejected" do
      expect {Promise.reject("this is an error").then {raise "test"}.await}.to raise_error "this is an error"
    end
    it "calls second method if the promise is rejected" do
      expect(Promise.reject("this is an error").then(nil, proc {"some text"}).await).to eq "some text"
    end
    it "does not call second method if the promise is resolved" do
      expect(Promise.resolve("this is something").then(nil, proc {raise "test"}).await).to eq "this is something"
    end
  end

  describe "::all" do
    it "rejects with a single reject" do
      p1 = Promise.new {sleep}
      p2 = Promise.reject("aaaaaaaaaaaa")
      p3 = Promise.resolve("bbbbb")
      expect {
        Promise.all([p1, p2, p3]).await
      }.to raise_error "aaaaaaaaaaaa"
    end
    it "fulfills with an array of values from all resolved" do
      expect(Promise.all((1..10).to_a.map! {|i| Promise.resolve(i)}).await).to match_array (1..10).to_a
    end
  end
end
