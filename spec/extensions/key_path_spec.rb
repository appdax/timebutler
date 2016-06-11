RSpec.describe KeyPath do
  it { expect({}).to respond_to :keypaths_for_nested_key }

  describe '#keypaths_for_nested_key' do
    subject { hsh.keypaths_for_nested_key key }

    context 'when nested key points to a hash' do
      let(:hsh) { { meta: { age: 1 } } }
      let(:key) { :age }

      it { is_expected.to eq(['meta.age']) }
    end

    context 'when nested key points to an array' do
      let(:hsh) { { events: [{ occurs_in: 1 }] } }
      let(:key) { :occurs_in }

      it { is_expected.to eq(['events.0.occurs_in']) }
    end
  end
end
