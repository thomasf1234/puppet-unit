RSpec.describe PuppetUnit::Lock do
  context "expired lock" do
    let(:expired_timestamp) { Time.now.to_i - (60*10) }
    let(:lock) { PuppetUnit::Lock.new("b4b24e67-bd12-4025-be74-3773d8cb64ec", expired_timestamp) }

    it "assigns the uuid" do
      expect(lock.uuid).to eq("b4b24e67-bd12-4025-be74-3773d8cb64ec")
    end

    it "assigns the expires_at_unix_timestamp" do
      expect(lock.expires_at_unix_timestamp).to eq(expired_timestamp)
      expect(lock.expires_at).to eq(Time.at(expired_timestamp))
    end

    it "is expired" do
      expect(lock.expired?).to eq(true)
    end

    it "is not active" do
      expect(lock.active?).to eq(false)
    end
  end

  context "active_lock" do
    let(:future_timestamp) { Time.now.to_i + (60*10) }
    let(:lock) { PuppetUnit::Lock.new("b4b24e67-bd12-4025-be74-3773d8cb64ec", future_timestamp) }

    it "assigns the uuid" do
      expect(lock.uuid).to eq("b4b24e67-bd12-4025-be74-3773d8cb64ec")
    end

    it "assigns the expires_at_unix_timestamp" do
      expect(lock.expires_at_unix_timestamp).to eq(future_timestamp)
      expect(lock.expires_at).to eq(Time.at(future_timestamp))
    end

    it "is not expired" do
      expect(lock.expired?).to eq(false)
    end

    it "is active" do
      expect(lock.active?).to eq(true)
    end
  end
end


