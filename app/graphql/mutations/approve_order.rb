class Mutations::ApproveOrder < Mutations::BaseMutation
  null true

  argument :id, ID, required: true

  field :order_or_error, Mutations::OrderOrFailureUnionType, 'A union of success/failure', null: false

  def resolve(id:)
    order = Order.find(id)
    validate_seller_request!(order)
    {
      order_or_error: { order: OrderService.approve!(order, by: context[:current_user]['id']) }
    }
  rescue Errors::ApplicationError => e
    { order_or_error: { error: Types::MutationErrorType.from_application(e) } }
  end
end
