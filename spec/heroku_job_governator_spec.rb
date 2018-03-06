require "spec_helper"

describe HerokuJobGovernator do
  it "has a version number" do
    expect(HerokuJobGovernator::VERSION).not_to be nil
  end

  describe ".configure" do
    it "validates the config" do
      expect {
        HerokuJobGovernator.configure do |config|
          config.queue_adapter = :blah
        end
      }.to raise_exception(InvalidHerokuGovernatorConfigError)
    end
  end

  describe ".config" do
    it "returns a new HerokuJobGovernator::Config" do
      expect(HerokuJobGovernator.config).to be_a(HerokuJobGovernator::Config)
    end
  end
end
