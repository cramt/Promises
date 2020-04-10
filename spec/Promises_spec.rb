RSpec.describe Promises do
    it "has a version number" do
        expect(Promises::VERSION).not_to be nil
    end
end

RSpec.describe Promise do
    it "is initially pending" do
        expect(Promise.new { sleep }).to be_pending
    end
end

RSpec.describe Promise do
    it "it raises error on rejects" do
        expect {
          Promise.new { |resolve, reject| reject.call "hello" }.await
        }.to raise_error "hello"
    end
end
