require 'json'
require 'taxjar'
require 'webmock/rspec'

def stub_tax_for_order
  stub_request(:post, Taxjar::API::Request::DEFAULT_API_URL + '/v2/taxes').to_return(body: sales_tax_fixture.to_json, headers: { content_type: 'application/json; charset=utf-8' })
end

def sales_tax_fixture
  {
    "tax": {
      "order_total_amount": 16.5,
      "shipping": 1.5,
      "taxable_amount": 16.5,
      "amount_to_collect": 1.16,
      "rate": 0.07,
      "has_nexus": true,
      "freight_taxable": true,
      "tax_source": 'destination',
      "breakdown": {
        "taxable_amount": 16.5,
        "tax_collectable": 1.16,
        "combined_tax_rate": 0.07,
        "state_taxable_amount": 16.5,
        "state_tax_rate": 0.07,
        "state_tax_collectable": 1.16,
        "county_taxable_amount": 0,
        "county_tax_rate": 0,
        "county_tax_collectable": 0,
        "city_taxable_amount": 0,
        "city_tax_rate": 0,
        "city_tax_collectable": 0,
        "special_district_taxable_amount": 0,
        "special_tax_rate": 0,
        "special_district_tax_collectable": 0,
        "shipping": {
          "taxable_amount": 1.5,
          "tax_collectable": 0.11,
          "combined_tax_rate": 0.07,
          "state_taxable_amount": 1.5,
          "state_sales_tax_rate": 0.07,
          "state_amount": 0.11,
          "county_taxable_amount": 0,
          "county_tax_rate": 0,
          "county_amount": 0,
          "city_taxable_amount": 0,
          "city_tax_rate": 0,
          "city_amount": 0,
          "special_taxable_amount": 0,
          "special_tax_rate": 0,
          "special_district_amount": 0
        },
        "line_items": [
          {
            "id": '1',
            "taxable_amount": 15,
            "tax_collectable": 1.05,
            "combined_tax_rate": 0.07,
            "state_taxable_amount": 15,
            "state_sales_tax_rate": 0.07,
            "state_amount": 1.05,
            "county_taxable_amount": 0,
            "county_tax_rate": 0,
            "county_amount": 0,
            "city_taxable_amount": 0,
            "city_tax_rate": 0,
            "city_amount": 0,
            "special_district_taxable_amount": 0,
            "special_tax_rate": 0,
            "special_district_amount": 0
          }
        ]
      }
    }
  }
end
