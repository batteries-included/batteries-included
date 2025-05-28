defmodule CommonCore.OpenAPI.Lago do
  @moduledoc false
  defmodule BillableMetricFilterInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :key, :string
      field :values, {:array, :string}
    end
  end

  defmodule SubscriptionCreateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :subscription, :map
    end
  end

  defmodule SubscriptionUpdateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :status, :string
      field :subscription, :map
    end
  end

  defmodule InvoiceOneOffCreateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :invoice, :map
    end
  end

  defmodule ApiErrorUnauthorized do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :error, :string
      field :status, :integer
    end
  end

  defmodule CustomerBillingConfiguration do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :document_locale, :string
      field :invoice_grace_period, :integer
      field :payment_provider, :string
      field :payment_provider_code, :string
      field :provider_customer_id, :string
      field :provider_payment_methods, {:array, :string}
      field :sync, :boolean
      field :sync_with_provider, :boolean
    end
  end

  defmodule CreditNoteUpdateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :credit_note, :map
    end
  end

  defmodule ApiErrorBadRequest do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :error, :string
      field :status, :integer
    end
  end

  defmodule BaseAppliedTax do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      field :amount_currency, :string
      field :created_at, :string
      field :lago_id, :string
      field :lago_tax_id, :string
      field :tax_code, :string
      field :tax_description, :string
      field :tax_name, :string
      field :tax_rate, :integer
    end
  end

  defmodule GrossRevenueObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      field :currency, :string
      field :month, :string
    end
  end

  defmodule WalletUpdateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :wallet, :map
    end
  end

  defmodule AppliedCouponInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :applied_coupon, :map
    end
  end

  defmodule GroupObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :key, :string
      field :lago_id, :string
      field :value, :string
    end
  end

  defmodule GrossRevenues do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :gross_revenues, GrossRevenueObject
    end
  end

  defmodule CreditNoteCreateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :credit_note, :map
    end
  end

  defmodule ChargeProperties do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount, :string
      field :fixed_amount, :string
      field :free_units, :integer
      field :free_units_per_events, :integer
      field :free_units_per_total_aggregation, :string
      field :graduated_percentage_ranges, {:array, :string}
      field :graduated_ranges, {:array, :string}
      field :grouped_by, {:array, :string}
      field :package_size, :integer
      field :per_transaction_max_amount, :string
      field :per_transaction_min_amount, :string
      field :rate, :string
      field :volume_ranges, {:array, :string}
    end
  end

  defmodule ChargeFilterInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :invoice_display_name, :string
      embeds_many :properties, ChargeProperties
      field :values, :map
    end
  end

  defmodule GroupPropertiesObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :group_id, :string
      field :invoice_display_name, :string
      embeds_many :values, ChargeProperties
    end
  end

  defmodule ChargeFilterObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :invoice_display_name, :string
      embeds_many :properties, ChargeProperties
      field :values, :map
    end
  end

  defmodule InvoiceUpdateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :invoice, :map
    end
  end

  defmodule CouponObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      field :amount_currency, :string
      field :billable_metric_codes, {:array, :string}
      field :code, :string
      field :coupon_type, :string
      field :created_at, :string
      field :description, :string
      field :expiration, :string
      field :expiration_at, :string
      field :frequency, :string
      field :frequency_duration, :integer
      field :lago_id, :string
      field :limited_billable_metrics, :boolean
      field :limited_plans, :boolean
      field :name, :string
      field :percentage_rate, :string
      field :plan_codes, {:array, :string}
      field :reusable, :boolean
      field :terminated_at, :string
    end
  end

  defmodule Coupon do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :coupon, CouponObject
    end
  end

  defmodule InvoicedUsageObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      field :code, :string
      field :currency, :string
      field :month, :string
    end
  end

  defmodule InvoicedUsages do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :invoiced_usages, InvoicedUsageObject
    end
  end

  defmodule MrrObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      field :currency, :string
      field :month, :string
    end
  end

  defmodule Mrrs do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :mrrs, MrrObject
    end
  end

  defmodule BillableMetricFilterObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :key, :string
      field :values, {:array, :string}
    end
  end

  defmodule PlanUpdateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :plan, :map
    end
  end

  defmodule CustomerMetadata do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :created_at, :string
      field :display_in_invoice, :boolean
      field :key, :string
      field :lago_id, :string
      field :value, :string
    end
  end

  defmodule CustomerObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :address_line1, :string
      field :address_line2, :string
      field :applicable_timezone, :string
      embeds_one :billing_configuration, CustomerBillingConfiguration
      field :city, :string
      field :country, :string
      field :created_at, :string
      field :currency, :string
      field :email, :string
      field :external_id, :string
      field :lago_id, :string
      field :legal_name, :string
      field :legal_number, :string
      field :logo_url, :string
      embeds_many :metadata, CustomerMetadata
      field :name, :string
      field :net_payment_term, :integer
      field :phone, :string
      field :sequential_id, :integer
      field :slug, :string
      field :state, :string
      field :tax_identification_number, :string
      field :timezone, :string
      field :updated_at, :string
      field :url, :string
      field :zipcode, :string
    end
  end

  defmodule AddOnBaseInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      field :amount_currency, :string
      field :code, :string
      field :description, :string
      field :invoice_display_name, :string
      field :name, :string
      field :tax_codes, {:array, :string}
    end
  end

  defmodule ApiErrorNotFound do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :code, :string
      field :error, :string
      field :status, :integer
    end
  end

  defmodule BillableMetricGroup do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :key, :string
      field :values, {:array, :string}
    end
  end

  defmodule BillableMetricObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :active_subscriptions_count, :integer
      field :aggregation_type, :string
      field :code, :string
      field :created_at, :string
      field :description, :string
      field :draft_invoices_count, :integer
      field :field_name, :string
      embeds_many :filters, BillableMetricFilterObject
      embeds_one :group, BillableMetricGroup
      field :lago_id, :string
      field :name, :string
      field :plans_count, :integer
      field :recurring, :boolean
      field :weighted_interval, :string
    end
  end

  defmodule BillableMetric do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :billable_metric, BillableMetricObject
    end
  end

  defmodule BillableMetricBaseInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :aggregation_type, :string
      field :code, :string
      field :description, :string
      field :field_name, :string
      embeds_many :filters, BillableMetricFilterInput
      embeds_one :group, BillableMetricGroup
      field :name, :string
      field :recurring, :boolean
      field :weighted_interval, :string
    end
  end

  defmodule BillableMetricCreateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :billable_metric, BillableMetricBaseInput
    end
  end

  defmodule BillableMetricUpdateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :billable_metric, BillableMetricBaseInput
    end
  end

  defmodule FeeUpdateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :fee, :map
    end
  end

  defmodule CreditNoteEstimated do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :estimated_credit_note, :map
    end
  end

  defmodule InvoiceCollectionObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      field :currency, :string
      field :invoices_count, :integer
      field :month, :string
      field :payment_status, :string
    end
  end

  defmodule WebhookEndpointCreateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :webhook_endpoint, :map
    end
  end

  defmodule EventEstimateFeesInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :event, :map
    end
  end

  defmodule ApiErrorUnprocessableEntity do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :code, :string
      field :error, :string
      field :error_details, :map
      field :status, :integer
    end
  end

  defmodule WalletTransactionObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount, :string
      field :created_at, :string
      field :credit_amount, :string
      field :lago_id, :string
      field :lago_wallet_id, :string
      field :settled_at, :string
      field :status, :string
      field :transaction_status, :string
      field :transaction_type, :string
    end
  end

  defmodule TaxBaseInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :applied_to_organization, :boolean
      field :code, :string
      field :description, :string
      field :name, :string
      field :rate, :string
    end
  end

  defmodule TaxCreateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :tax, TaxBaseInput
    end
  end

  defmodule PlanCreateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :plan, :map
    end
  end

  defmodule CustomerCreateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :customer, :map
    end
  end

  defmodule CouponBaseInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      field :amount_currency, :string
      field :applies_to, :map
      field :code, :string
      field :coupon_type, :string
      field :description, :string
      field :expiration, :string
      field :expiration_at, :string
      field :frequency, :string
      field :frequency_duration, :integer
      field :name, :string
      field :percentage_rate, :string
      field :reusable, :boolean
    end
  end

  defmodule CouponCreateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :coupon, CouponBaseInput
    end
  end

  defmodule ApiErrorNotAllowed do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :code, :string
      field :error, :string
      field :status, :integer
    end
  end

  defmodule EventInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :event, :map
    end
  end

  defmodule EventBatchInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :events, EventInput
    end
  end

  defmodule CustomerChargeUsageObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      field :amount_currency, :string
      field :billable_metric, :map
      field :charge, :map
      field :events_count, :integer
      field :filters, {:array, :map}
      field :grouped_usage, {:array, :map}
      field :groups, {:array, :map}
      field :units, :string
    end
  end

  defmodule CustomerUsageObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      embeds_many :charges_usage, CustomerChargeUsageObject
      field :currency, :string
      field :from_datetime, :string
      field :issuing_date, :string
      field :lago_invoice_id, :string
      field :taxes_amount_cents, :integer
      field :to_datetime, :string
      field :total_amount_cents, :integer
    end
  end

  defmodule CustomerUsage do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :customer_usage, CustomerUsageObject
    end
  end

  defmodule WalletCreateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :wallet, :map
    end
  end

  defmodule EventObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :code, :string
      field :created_at, :string
      field :external_customer_id, :string
      field :external_subscription_id, :string
      field :lago_customer_id, :string
      field :lago_id, :string
      field :lago_subscription_id, :string
      field :properties, :map
      field :timestamp, :string
      field :transaction_id, :string
    end
  end

  defmodule Event do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :event, EventObject
    end
  end

  defmodule ApiErrorForbidden do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :code, :string
      field :error, :string
      field :status, :integer
    end
  end

  defmodule CreditNoteEstimateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :credit_note, :map
    end
  end

  defmodule PaginationMeta do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :current_page, :integer
      field :next_page, :integer
      field :prev_page, :integer
      field :total_count, :integer
      field :total_pages, :integer
    end
  end

  defmodule CustomerPastUsage do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :meta, PaginationMeta
      embeds_many :usage_periods, CustomerUsage
    end
  end

  defmodule GroupsPaginated do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :groups, GroupObject
      embeds_one :meta, PaginationMeta
    end
  end

  defmodule WalletTransactionsPaginated do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :meta, PaginationMeta
      embeds_many :wallet_transactions, WalletTransactionObject
    end
  end

  defmodule CouponsPaginated do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :coupons, CouponObject
      embeds_one :meta, PaginationMeta
    end
  end

  defmodule TaxObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :add_ons_count, :integer
      field :applied_to_organization, :boolean
      field :charges_count, :integer
      field :code, :string
      field :created_at, :string
      field :customers_count, :integer
      field :description, :string
      field :lago_id, :string
      field :name, :string
      field :plans_count, :integer
      field :rate, :integer
    end
  end

  defmodule TaxesPaginated do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :meta, PaginationMeta
      embeds_many :taxes, TaxObject
    end
  end

  defmodule CustomerObjectExtended do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :address_line1, :string
      field :address_line2, :string
      field :applicable_timezone, :string
      embeds_one :billing_configuration, CustomerBillingConfiguration
      field :city, :string
      field :country, :string
      field :created_at, :string
      field :currency, :string
      field :email, :string
      field :external_id, :string
      field :lago_id, :string
      field :legal_name, :string
      field :legal_number, :string
      field :logo_url, :string
      embeds_many :metadata, CustomerMetadata
      field :name, :string
      field :net_payment_term, :integer
      field :phone, :string
      field :sequential_id, :integer
      field :slug, :string
      field :state, :string
      field :tax_identification_number, :string
      embeds_many :taxes, TaxObject
      field :timezone, :string
      field :updated_at, :string
      field :url, :string
      field :zipcode, :string
    end
  end

  defmodule ChargeObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :billable_metric_code, :string
      field :charge_model, :string
      field :created_at, :string
      embeds_many :filters, ChargeFilterObject
      embeds_many :group_properties, GroupPropertiesObject
      field :invoice_display_name, :string
      field :invoiceable, :boolean
      field :lago_billable_metric_id, :string
      field :lago_id, :string
      field :min_amount_cents, :integer
      field :pay_in_advance, :boolean
      embeds_many :properties, ChargeProperties
      field :prorated, :boolean
      embeds_many :taxes, TaxObject
    end
  end

  defmodule Tax do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :tax, TaxObject
    end
  end

  defmodule AddOnObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      field :amount_currency, :string
      field :code, :string
      field :created_at, :string
      field :description, :string
      field :invoice_display_name, :string
      field :lago_id, :string
      field :name, :string
      embeds_many :taxes, TaxObject
    end
  end

  defmodule AddOnsPaginated do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :add_ons, AddOnObject
      embeds_one :meta, PaginationMeta
    end
  end

  defmodule AddOn do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :add_on, AddOnObject
    end
  end

  defmodule CustomersPaginated do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :customers, CustomerObjectExtended
      embeds_one :meta, PaginationMeta
    end
  end

  defmodule Customer do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :customer, CustomerObjectExtended
    end
  end

  defmodule WalletTransactionCreateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :wallet_transaction, :map
    end
  end

  defmodule WalletTransactions do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :wallet_transactions, WalletTransactionObject
    end
  end

  defmodule CreditObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      field :amount_currency, :string
      field :before_taxes, :boolean
      field :invoice, :map
      field :item, :map
      field :lago_id, :string
    end
  end

  defmodule SubscriptionObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :billing_time, :string
      field :canceled_at, :string
      field :created_at, :string
      field :downgrade_plan_date, :string
      field :ending_at, :string
      field :external_customer_id, :string
      field :external_id, :string
      field :lago_customer_id, :string
      field :lago_id, :string
      field :name, :string
      field :next_plan_code, :string
      field :plan_code, :string
      field :previous_plan_code, :string
      field :started_at, :string
      field :status, :string
      field :subscription_at, :string
      field :terminated_at, :string
      field :trial_ended_at, :string
    end
  end

  defmodule SubscriptionsPaginated do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :meta, PaginationMeta
      embeds_many :subscriptions, SubscriptionObject
    end
  end

  defmodule CreditNoteAppliedTaxObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      field :amount_currency, :string
      field :base_amount_cents, :integer
      field :created_at, :string
      field :lago_credit_note_id, :string
      field :lago_id, :string
      field :lago_tax_id, :string
      field :tax_code, :string
      field :tax_description, :string
      field :tax_name, :string
      field :tax_rate, :integer
    end
  end

  defmodule AppliedCouponObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      field :amount_cents_remaining, :integer
      field :amount_currency, :string
      field :coupon_code, :string
      field :coupon_name, :string
      field :created_at, :string
      field :expiration_at, :string
      field :external_customer_id, :string
      field :frequency, :string
      field :frequency_duration, :integer
      field :frequency_duration_remaining, :integer
      field :lago_coupon_id, :string
      field :lago_customer_id, :string
      field :lago_id, :string
      field :percentage_rate, :string
      field :status, :string
      field :terminated_at, :string
    end
  end

  defmodule AppliedCoupon do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :applied_coupon, AppliedCouponObject
    end
  end

  defmodule InvoiceMetadataObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :created_at, :string
      field :key, :string
      field :lago_id, :string
      field :value, :string
    end
  end

  defmodule MinimumCommitmentObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      field :created_at, :string
      field :interval, :string
      field :invoice_display_name, :string
      field :lago_id, :string
      field :plan_code, :string
      embeds_many :taxes, TaxObject
      field :updated_at, :string
    end
  end

  defmodule MinimumCommitmentInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      field :invoice_display_name, :string
      field :tax_codes, {:array, :string}
    end
  end

  defmodule InvoiceCollections do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :invoice_collections, InvoiceCollectionObject
    end
  end

  defmodule WebhookEndpointUpdateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :webhook_endpoint, :map
    end
  end

  defmodule OrganizationBillingConfiguration do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :document_locale, :string
      field :invoice_footer, :string
      field :invoice_grace_period, :integer
    end
  end

  defmodule OrganizationObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :address_line1, :string
      field :address_line2, :string
      embeds_one :billing_configuration, OrganizationBillingConfiguration
      field :city, :string
      field :country, :string
      field :created_at, :string
      field :default_currency, :string
      field :document_number_prefix, :string
      field :document_numbering, :string
      field :email, :string
      field :lago_id, :string
      field :legal_name, :string
      field :legal_number, :string
      field :name, :string
      field :net_payment_term, :integer
      field :state, :string
      field :tax_identification_number, :string
      embeds_many :taxes, TaxObject
      field :timezone, :string
      field :webhook_url, :string
      field :webhook_urls, {:array, :string}
      field :zipcode, :string
    end
  end

  defmodule Organization do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :organization, OrganizationObject
    end
  end

  defmodule OrganizationUpdateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :organization, :map
    end
  end

  defmodule FeeAppliedTaxObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      field :amount_currency, :string
      field :created_at, :string
      field :lago_fee_id, :string
      field :lago_id, :string
      field :lago_tax_id, :string
      field :tax_code, :string
      field :tax_description, :string
      field :tax_name, :string
      field :tax_rate, :integer
    end
  end

  defmodule AddOnCreateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :add_on, AddOnBaseInput
    end
  end

  defmodule AddOnUpdateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :add_on, AddOnBaseInput
    end
  end

  defmodule AppliedCouponObjectExtended do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      field :amount_cents_remaining, :integer
      field :amount_currency, :string
      field :coupon_code, :string
      field :coupon_name, :string
      field :created_at, :string
      embeds_many :credits, CreditObject
      field :expiration_at, :string
      field :external_customer_id, :string
      field :frequency, :string
      field :frequency_duration, :integer
      field :frequency_duration_remaining, :integer
      field :lago_coupon_id, :string
      field :lago_customer_id, :string
      field :lago_id, :string
      field :percentage_rate, :string
      field :status, :string
      field :terminated_at, :string
    end
  end

  defmodule AppliedCouponsPaginated do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :applied_coupons, AppliedCouponObjectExtended
      embeds_one :meta, PaginationMeta
    end
  end

  defmodule BillableMetricsPaginated do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :billable_metrics, BillableMetricObject
      embeds_one :meta, PaginationMeta
    end
  end

  defmodule CouponUpdateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :coupon, CouponBaseInput
    end
  end

  defmodule FeeObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      field :amount_currency, :string
      field :amount_details, :map
      embeds_many :applied_taxes, FeeAppliedTaxObject
      field :created_at, :string
      field :event_transaction_id, :string
      field :events_count, :integer
      field :external_customer_id, :string
      field :external_subscription_id, :string
      field :failed_at, :string
      field :from_date, :string
      field :invoice_display_name, :string
      field :invoiceable, :boolean
      field :item, :map
      field :lago_charge_filter_id, :string
      field :lago_customer_id, :string
      field :lago_group_id, :string
      field :lago_id, :string
      field :lago_invoice_id, :string
      field :lago_subscription_id, :string
      field :lago_true_up_fee_id, :string
      field :lago_true_up_parent_fee_id, :string
      field :pay_in_advance, :boolean
      field :payment_status, :string
      field :precise_unit_amount, :string
      field :refunded_at, :string
      field :succeeded_at, :string
      field :taxes_amount_cents, :integer
      field :taxes_rate, :integer
      field :to_date, :string
      field :total_amount_cents, :integer
      field :total_amount_currency, :string
      field :units, :string
    end
  end

  defmodule CreditNoteItemObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      field :amount_currency, :string
      embeds_many :fee, FeeObject
      field :lago_id, :string
    end
  end

  defmodule CreditNoteObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :applied_taxes, CreditNoteAppliedTaxObject
      field :balance_amount_cents, :integer
      field :coupons_adjustment_amount_cents, :integer
      field :created_at, :string
      field :credit_amount_cents, :integer
      field :credit_status, :string
      field :currency, :string
      field :description, :string
      field :file_url, :string
      field :invoice_number, :string
      field :issuing_date, :string
      embeds_many :items, CreditNoteItemObject
      field :lago_id, :string
      field :lago_invoice_id, :string
      field :number, :string
      field :reason, :string
      field :refund_amount_cents, :integer
      field :refund_status, :string
      field :sequential_id, :integer
      field :sub_total_excluding_taxes_amount_cents, :integer
      field :taxes_amount_cents, :integer
      field :taxes_rate, :integer
      field :total_amount_cents, :integer
      field :updated_at, :string
    end
  end

  defmodule CreditNote do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :credit_note, CreditNoteObject
    end
  end

  defmodule CreditNotes do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :credit_notes, CreditNoteObject
    end
  end

  defmodule Fee do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :fee, FeeObject
    end
  end

  defmodule Fees do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :fees, FeeObject
    end
  end

  defmodule FeesPaginated do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :fees, FeeObject
      embeds_one :meta, PaginationMeta
    end
  end

  defmodule InvoiceAppliedTaxObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      field :amount_currency, :string
      field :created_at, :string
      field :fees_amount_cents, :integer
      field :lago_id, :string
      field :lago_invoice_id, :string
      field :lago_tax_id, :string
      field :tax_code, :string
      field :tax_description, :string
      field :tax_name, :string
      field :tax_rate, :integer
    end
  end

  defmodule InvoiceObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :applied_taxes, InvoiceAppliedTaxObject
      field :coupons_amount_cents, :integer
      field :credit_notes_amount_cents, :integer
      field :currency, :string
      embeds_many :customer, CustomerObject
      field :fees_amount_cents, :integer
      field :file_url, :string
      field :invoice_type, :string
      field :issuing_date, :string
      field :lago_id, :string
      embeds_many :metadata, InvoiceMetadataObject
      field :net_payment_term, :integer
      field :number, :string
      field :payment_dispute_lost_at, :string
      field :payment_due_date, :string
      field :payment_status, :string
      field :prepaid_credit_amount_cents, :integer
      field :sequential_id, :integer
      field :status, :string
      field :sub_total_excluding_taxes_amount_cents, :integer
      field :sub_total_including_taxes_amount_cents, :integer
      field :taxes_amount_cents, :integer
      field :total_amount_cents, :integer
      field :version_number, :integer
    end
  end

  defmodule InvoiceObjectExtended do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :applied_taxes, InvoiceAppliedTaxObject
      field :coupons_amount_cents, :integer
      field :credit_notes_amount_cents, :integer
      embeds_many :credits, CreditObject
      field :currency, :string
      embeds_many :customer, CustomerObject
      embeds_many :fees, FeeObject
      field :fees_amount_cents, :integer
      field :file_url, :string
      field :invoice_type, :string
      field :issuing_date, :string
      field :lago_id, :string
      embeds_many :metadata, InvoiceMetadataObject
      field :net_payment_term, :integer
      field :number, :string
      field :payment_dispute_lost_at, :string
      field :payment_due_date, :string
      field :payment_status, :string
      field :prepaid_credit_amount_cents, :integer
      field :sequential_id, :integer
      field :status, :string
      field :sub_total_excluding_taxes_amount_cents, :integer
      field :sub_total_including_taxes_amount_cents, :integer
      embeds_many :subscriptions, SubscriptionObject
      field :taxes_amount_cents, :integer
      field :total_amount_cents, :integer
      field :version_number, :integer
    end
  end

  defmodule Invoice do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :invoice, InvoiceObjectExtended
    end
  end

  defmodule InvoicesPaginated do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :invoices, InvoiceObject
      embeds_one :meta, PaginationMeta
    end
  end

  defmodule PlanObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :active_subscriptions_count, :integer
      field :amount_cents, :integer
      field :amount_currency, :string
      field :bill_charges_monthly, :boolean
      embeds_many :charges, ChargeObject
      field :code, :string
      field :created_at, :string
      field :description, :string
      field :draft_invoices_count, :integer
      field :interval, :string
      field :invoice_display_name, :string
      field :lago_id, :string
      embeds_one :minimum_commitment, MinimumCommitmentObject
      field :name, :string
      field :pay_in_advance, :boolean
      embeds_many :taxes, TaxObject
      field :trial_period, :integer
    end
  end

  defmodule Plan do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :plan, PlanObject
    end
  end

  defmodule PlanOverridesObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :amount_cents, :integer
      field :amount_currency, :string
      field :charges, {:array, :string}
      field :description, :string
      field :invoice_display_name, :string
      embeds_one :minimum_commitment, MinimumCommitmentObject
      field :name, :string
      field :tax_codes, {:array, :string}
      field :trial_period, :integer
    end
  end

  defmodule PlansPaginated do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :meta, PaginationMeta
      embeds_many :plans, PlanObject
    end
  end

  defmodule SubscriptionObjectExtended do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :billing_time, :string
      field :canceled_at, :string
      field :created_at, :string
      field :downgrade_plan_date, :string
      field :ending_at, :string
      field :external_customer_id, :string
      field :external_id, :string
      field :lago_customer_id, :string
      field :lago_id, :string
      field :name, :string
      field :next_plan_code, :string
      embeds_one :plan, PlanObject
      field :plan_code, :string
      field :previous_plan_code, :string
      field :started_at, :string
      field :status, :string
      field :subscription_at, :string
      field :terminated_at, :string
      field :trial_ended_at, :string
    end
  end

  defmodule Subscription do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :subscription, SubscriptionObjectExtended
    end
  end

  defmodule TaxUpdateInput do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :tax, TaxBaseInput
    end
  end

  defmodule WalletObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :balance_cents, :integer
      field :consumed_credits, :string
      field :created_at, :string
      field :credits_balance, :string
      field :credits_ongoing_balance, :string
      field :credits_ongoing_usage_balance, :string
      field :currency, :string
      field :expiration_at, :string
      field :external_customer_id, :string
      field :lago_customer_id, :string
      field :lago_id, :string
      field :last_balance_sync_at, :string
      field :last_consumed_credit_at, :string
      field :name, :string
      field :ongoing_balance_cents, :integer
      field :ongoing_usage_balance_cents, :integer
      field :rate_amount, :string
      field :recurring_transaction_rules, {:array, :string}
      field :status, :string
      field :terminated_at, :string
    end
  end

  defmodule Wallet do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :wallet, WalletObject
    end
  end

  defmodule WalletsPaginated do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :meta, PaginationMeta
      embeds_many :wallets, WalletObject
    end
  end

  defmodule WebhookEndpointObject do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :created_at, :string
      field :lago_id, :string
      field :lago_organization_id, :string
      field :signature_algo, :string
      field :webhook_url, :string
    end
  end

  defmodule WebhookEndpoint do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :webhook_endpoint, WebhookEndpointObject
    end
  end

  defmodule WebhookEndpointsPaginated do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :meta, PaginationMeta
      embeds_many :webhook_endpoints, WebhookEndpointObject
    end
  end
end
