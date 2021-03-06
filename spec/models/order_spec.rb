require 'rails_helper'

RSpec.describe Order, type: :model do
  let(:order) { Fabricate(:order) }

  describe 'update_state_timestamps' do
    it 'sets state timestamps in create' do
      expect(order.state_updated_at).not_to be_nil
      expect(order.state_expires_at).to eq order.state_updated_at + 2.days
    end

    it 'does not update timestamps if state did not change' do
      current_timestamp = order.state_updated_at
      order.update!(currency_code: 'CAD')
      expect(order.state_updated_at).to eq current_timestamp
    end

    it 'updates timestamps if state changed to state with expiration' do
      current_timestamp = order.state_updated_at
      current_expiration = order.state_expires_at
      order.submit!
      order.save!
      expect(order.state_updated_at).not_to eq current_timestamp
      expect(order.state_expires_at).not_to eq current_expiration
    end
    it 'does not update expiration timestamp if state changed to state without expiration' do
      order.submit!
      order.save!
      submitted_timestamp = order.state_updated_at
      order.reject!
      order.save!
      expect(order.state_updated_at).not_to eq submitted_timestamp
      expect(order.state_expires_at).to be_nil
    end
  end

  describe '#shipping_info' do
    context 'with Ship fulfillment type' do
      it 'returns true when all required shipping data available' do
        order.update!(fulfillment_type: Order::PICKUP, shipping_name: 'Fname Lname', shipping_country: 'IR', shipping_address_line1: 'Vanak', shipping_address_line2: nil, shipping_postal_code: '09821', buyer_phone_number: '0923', shipping_city: 'Tehran')
        expect(order.shipping_info?).to be true
      end
      it 'returns false if missing any shipping data' do
        order.update!(fulfillment_type: Order::SHIP, shipping_name: 'Fname Lname', shipping_country: 'IR', shipping_address_line1: nil, shipping_postal_code: nil, buyer_phone_number: nil)
        expect(order.shipping_info?).to be false
      end
    end
    context 'with Pickup fulfillment type' do
      it 'returns true' do
        order.update!(fulfillment_type: Order::PICKUP, shipping_name: 'Fname Lname', shipping_country: nil, shipping_address_line1: nil, shipping_postal_code: nil, buyer_phone_number: nil)
        expect(order.shipping_info?).to be true
      end
    end
  end

  describe '#code' do
    it 'sets code in proper format' do
      expect(order.code).to match(/^B\d{6}$/)
    end
  end

  describe '#create_state_history' do
    context 'when an order is first created' do
      it 'creates a new state history object with its initial state' do
        new_order = Order.create!(state: Order::PENDING)
        expect(new_order.state_histories.count).to eq 1
        expect(new_order.state_histories.last.state).to eq Order::PENDING
        expect(new_order.state_histories.last.updated_at.to_i).to eq new_order.state_updated_at.to_i
      end
    end
    context 'when an order changes state' do
      it 'creates a new state history object with the new state' do
        order.submit!
        expect(order.state_histories.count).to eq 2 # PENDING and SUBMITTED
        expect(order.state_histories.last.state).to eq Order::SUBMITTED
        expect(order.state_histories.last.updated_at.to_i).to eq order.state_updated_at.to_i
      end
    end
  end

  describe '#last_submitted_at' do
    context 'with a submitted order' do
      it 'returns the time at which the order was submitted' do
        order.submit!
        expect(order.last_submitted_at.to_i).to eq order.state_histories.find_by(state: Order::SUBMITTED).updated_at.to_i
      end
    end
    context 'with an unsubmitted order' do
      it 'returns nil' do
        expect(order.last_submitted_at).to be_nil
      end
    end
  end

  describe '#last_approved_at' do
    context 'with an approved order' do
      it 'returns the time at which the order was approved' do
        order.update!(state: Order::SUBMITTED)
        order.approve!
        expect(order.last_approved_at.to_i).to eq order.state_histories.find_by(state: Order::APPROVED).updated_at.to_i
      end
    end
    context 'with an un-approved order' do
      it 'returns nil' do
        expect(order.last_approved_at).to be_nil
      end
    end
  end
end
