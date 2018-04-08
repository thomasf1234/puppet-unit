RSpec.describe PuppetUnit::Services::LockfileService do
  describe "#get" do
    let(:lock) { PuppetUnit::Services::LockfileService.instance.get }

    it "has a random uuid" do
      uuid_regex = /[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}/
      expect(lock.uuid).to match(uuid_regex)
    end

    it "returns a lock with an expiry date of 5 hours" do
      four_hours_from_now = Time.at(Time.now.to_i + (60*60*4))
      six_hours_from_now = Time.at(Time.now.to_i + (60*60*6))
      expect(lock.expires_at > four_hours_from_now).to eq(true)
      expect(lock.expires_at < six_hours_from_now).to eq(true)
    end
  end

  describe "#write/read" do
    let(:lockfile_path) { "tmp/lockfile.marshal"}

    context "file does not exist" do
      it "can write/read the lockfile" do
        lock = PuppetUnit::Services::LockfileService.instance.get

        expect(File.exist?(lockfile_path)).to eq(false)
        PuppetUnit::Services::LockfileService.instance.write(lock, lockfile_path)
        expect(File.exist?(lockfile_path)).to eq(true)

        lock2 = PuppetUnit::Services::LockfileService.instance.read(lockfile_path)

        expect(lock2.uuid).to eq(lock.uuid)
        expect(lock2.expires_at_unix_timestamp).to eq(lock.expires_at_unix_timestamp)
      end
    end

    context "file already exists" do
      it "raises an exception" do
        lock = PuppetUnit::Services::LockfileService.instance.get

        expect(File.exist?(lockfile_path)).to eq(false)
        PuppetUnit::Services::LockfileService.instance.write(lock, lockfile_path)
        expect(File.exist?(lockfile_path)).to eq(true)

        begin
          PuppetUnit::Services::LockfileService.instance.write(lock, lockfile_path)
          fail("Should have raised PuppetUnit::Exceptions::LockfileExists")
        rescue PuppetUnit::Exceptions::LockfileExists => e
          expect(e.lockfile_path).to eq(lockfile_path)
        end
      end
    end
  end
end


