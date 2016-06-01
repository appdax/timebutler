require 'yaml'
require 'hashdiff'

RSpec.describe TimeButler do
  let!(:stocks) { described_class.instance.send(:db)[:stocks] }
  let!(:fb) { YAML.load IO.read('spec/fixtures/facebook.yaml') }

  before do
    stocks.drop
    stocks.insert_one fb
  end

  describe '#run' do
    before { Timecop.freeze(time) }

    context 'when the stock has been updated today' do
      let(:time) { Time.utc(2016, 5, 1) }
      subject { stocks.find(_id: 'US30303M1027').first }

      context 'when traveling ahead' do
        before { TimeButler.go_ahead }

        it('should do nothing') do
          expect(HashDiff.diff(subject, fb)).to be_empty
        end
      end

      context 'when traveling back' do
        before { TimeButler.go_back }

        it('should do nothing') do
          expect(HashDiff.diff(subject, fb)).to be_empty
        end
      end
    end

    context 'when the stock is outdated' do
      let(:time) { Time.utc(2016, 5, 2, 23, 59) }
      let(:expected) { YAML.load IO.read(fixture) }
      subject { stocks.find(_id: 'US30303M1027').first }

      context 'when traveling ahead' do
        let(:fixture) { 'spec/fixtures/facebook.ahead.yaml' }
        before { TimeButler.go_ahead }

        it('should do nothing') do
          expect(HashDiff.diff(subject, expected)).to be_empty
        end
      end

      context 'when traveling back' do
        let(:fixture) { 'spec/fixtures/facebook.back.yaml' }
        before { TimeButler.go_back }

        it('should do nothing') do
          expect(HashDiff.diff(subject, expected)).to be_empty
        end
      end
    end
  end
end
