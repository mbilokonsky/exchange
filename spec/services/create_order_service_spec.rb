require 'rails_helper'
require 'support/gravity_helper'

describe CreateOrderService, type: :services do
  describe '#with_artwork!' do
    let(:user_id) { 'user-id' }
    context 'with known artwork' do
      before do
        expect(Adapters::GravityV1).to receive(:get).and_return(gravity_v1_artwork)
      end
      context 'without edition set' do
        it 'create order with proper data' do
          expect do
            order = CreateOrderService.with_artwork!(user_id: user_id, artwork_id: 'artwork-id', edition_set_id: nil, quantity: 2)
            expect(order.currency_code).to eq 'USD'
            expect(order.buyer_id).to eq user_id
            expect(order.seller_id).to eq 'gravity-partner-id'
            expect(order.line_items.count).to eq 1
            expect(order.line_items.first.price_cents).to eq 5400_12
            expect(order.line_items.first.artwork_id).to eq 'artwork-id'
            expect(order.line_items.first.edition_set_id).to be_nil
            expect(order.line_items.first.quantity).to eq 2
            expect(order.items_total_cents).to eq 1080024
          end.to change(Order, :count).by(1).and change(LineItem, :count).by(1)
        end
        it 'sets state_expires_at for newly pending order' do
          Timecop.freeze(Time.now.utc) do
            order = CreateOrderService.with_artwork!(user_id: user_id, artwork_id: 'artwork-id', edition_set_id: nil, quantity: 2)
            expect(order.state).to eq Order::PENDING
            expect(order.state_updated_at).to eq Time.now.utc
            expect(order.state_expires_at).to eq 2.days.from_now
          end
        end
      end
      context 'with edition set' do
        it 'creates order with proper data' do
          expect do
            order = CreateOrderService.with_artwork!(user_id: user_id, artwork_id: 'artwork-id', edition_set_id: 'edition-set-id', quantity: 2)
            expect(order.currency_code).to eq 'USD'
            expect(order.buyer_id).to eq user_id
            expect(order.seller_id).to eq 'gravity-partner-id'
            expect(order.line_items.count).to eq 1
            expect(order.line_items.first.price_cents).to eq 4200_42
            expect(order.line_items.first.artwork_id).to eq 'artwork-id'
            expect(order.line_items.first.edition_set_id).to eq 'edition-set-id'
            expect(order.line_items.first.quantity).to eq 2
            job = ActiveJob::Base.queue_adapter.enqueued_jobs.detect { |j| j[:job] == OrderFollowUpJob }
            expect(job).to_not be_nil
            expect(job[:at].to_i).to eq order.reload.state_expires_at.to_i
            expect(job[:args][0]).to eq order.id
            expect(job[:args][1]).to eq Order::PENDING
          end.to change(Order, :count).by(1).and change(LineItem, :count).by(1)
        end
      end
    end
    context 'with unknown artwork' do
      before do
        expect(Adapters::GravityV1).to receive(:get).and_raise(Adapters::GravityError.new('unknown artwork'))
      end
      it 'raises Errors::OrderError' do
        expect { CreateOrderService.with_artwork!(user_id: user_id, artwork_id: 'random-artwork', quantity: 2) }.to raise_error(Errors::OrderError)
      end
    end
  end

  describe '#artwork_price' do
    context 'for artwork' do
      it 'returns artwork price' do
        expect(CreateOrderService.artwork_price(gravity_v1_artwork)).to eq 5400_12
      end
    end
    context 'for edition set' do
      it 'returns edition_set_price for known edition set id' do
        expect(CreateOrderService.artwork_price(gravity_v1_artwork, edition_set_id: 'edition-set-id')).to eq 4200_42
      end
      it 'raises Errors::OrderError for unknown edition set id' do
        expect { CreateOrderService.artwork_price(gravity_v1_artwork, edition_set_id: 'random-id') }.to raise_error(Errors::OrderError, /Unknown edition set/)
      end
    end
  end
end
