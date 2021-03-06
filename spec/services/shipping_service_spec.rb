require 'rails_helper'
require 'support/gravity_helper'

describe ShippingService, type: :services do
  let(:artwork_location) do
    {
      country: 'US',
      city: 'Brooklyn',
      state: 'NY'
    }
  end
  let(:artwork_shipping_setting) do
    {
      domestic_shipping_fee_cents: 100_00,
      international_shipping_fee_cents: 500_00,
      location: artwork_location
    }
  end
  let(:artwork) { gravity_v1_artwork(artwork_shipping_setting) }
  describe '#calculate_shipping' do
    let(:artwork) { gravity_v1_artwork }
    let(:line_item) { Fabricate(:line_item, artwork_id: 'gravity-id') }
    context 'with successful artwork fetch call' do
      before do
        allow(Adapters::GravityV1).to receive(:get).with('/artwork/gravity-id').and_return(artwork)
      end
      context 'with pickup fulfillment type' do
        it 'returns 0' do
          expect(ShippingService.calculate_shipping(artwork: artwork, fulfillment_type: Order::PICKUP, shipping_country: 'US')).to eq 0
        end
      end
      context 'with domestic address' do
        it 'returns domestic cost' do
          expect(ShippingService.calculate_shipping(artwork: artwork, fulfillment_type: Order::SHIP, shipping_country: 'US')).to eq 100_00
        end
      end
      context 'with international address' do
        it 'returns international cost' do
          expect(ShippingService.calculate_shipping(artwork: artwork, fulfillment_type: Order::SHIP, shipping_country: 'Iran')).to eq 500_00
        end
      end
    end
  end

  describe '#domestic?' do
    it 'returns true for artworks in the same country as shipping' do
      expect(ShippingService.domestic?(artwork_location, 'US')).to be true
    end

    it 'returns false for artworks not in the same country as shipping' do
      expect(ShippingService.domestic?(artwork_location, 'IR')).to be false
    end
  end

  describe '#calculate_domestic' do
    it 'returns domestic shipping cost' do
      expect(ShippingService.calculate_domestic(artwork)).to eq 100_00
    end

    context 'with nil domestic shipping' do
      let(:artwork_shipping_setting) do
        {
          domestic_shipping_fee_cents: nil,
          international_shipping_fee_cents: 500_00,
          location: artwork_location
        }
      end
      it 'raises error' do
        expect { ShippingService.calculate_domestic(artwork) }.to raise_error(Errors::OrderError, /Artwork is missing shipping fee/)
      end
    end
  end

  describe '#calculate_international' do
    it 'returns international shipping cost' do
      expect(ShippingService.calculate_international(artwork)).to eq 500_00
    end
    context 'with nil domestic shipping' do
      let(:artwork_shipping_setting) do
        {
          domestic_shipping_fee_cents: 100_00,
          international_shipping_fee_cents: nil,
          location: artwork_location
        }
      end
      it 'raises error' do
        expect { ShippingService.calculate_international(artwork) }.to raise_error(Errors::OrderError, /Artwork is missing shipping fee/)
      end
    end
  end
end
