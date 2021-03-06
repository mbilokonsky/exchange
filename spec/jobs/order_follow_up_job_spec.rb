require 'rails_helper'
require 'timecop'

describe OrderFollowUpJob, type: :job do
  let(:state) { Order::PENDING }
  let(:order) { Fabricate(:order, state: state) }
  describe '#perform' do
    context 'with an order in the same state after its expiration time' do
      context 'expired PENDING' do
        it 'transitions to abandoned' do
          Timecop.freeze(order.state_expires_at + 1.second) do
            expect(OrderService).to receive(:abandon!).with(order)
            OrderFollowUpJob.perform_now(order.id, Order::PENDING)
          end
        end
      end
      context 'expired SUBMITTED' do
        let(:state) { Order::SUBMITTED }
        it 'transitions a submitted order to seller_lapsed' do
          Timecop.freeze(order.state_expires_at + 1.second) do
            expect(OrderService).to receive(:seller_lapse!).with(order)
            OrderFollowUpJob.perform_now(order.id, Order::SUBMITTED)
          end
        end
      end
      context 'expired APPROVED' do
        let(:state) { Order::APPROVED }
        it 'posts an event' do
          Timecop.freeze(order.state_expires_at + 1.second) do
            expect(OrderEvent).to receive(:post).with(order, 'unfulfilled', nil)
            OrderFollowUpJob.perform_now(order.id, Order::APPROVED)
          end
        end
      end
    end
    context 'with an order in a different state than when the job was made' do
      it 'does nothing' do
        order.update!(state: Order::SUBMITTED)
        Timecop.freeze(order.state_expires_at + 1.second) do
          expect(OrderService).to_not receive(:abandon!)
          expect(OrderService).to_not receive(:seller_lapse!)
          OrderFollowUpJob.perform_now(order.id, Order::PENDING)
        end
      end
    end
    context 'with an order in the same state before its expiration time' do
      it 'does nothing' do
        expect(OrderService).to_not receive(:abandon!)
        expect(OrderService).to_not receive(:seller_lapse!)
        OrderFollowUpJob.perform_now(order.id, Order::PENDING)
      end
    end
  end
end
