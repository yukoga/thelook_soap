# =============================================================================
# Part 2-1: Looker (Google Cloud Core) Semantic Layer Views & Measures
# Looker Core Instance : https://looker001.yukoga.demo.altostrat.com/
# Target BigQuery      : yukoga-sandbox-001.thelook_soap
# Scope Design         : Defines deterministic Dimensions & Measures for core
#                        Sales & Inventory KPIs (resolving Task 1 & Task 2),
#                        while intentionally leaving complex cross-policy rules
#                        (Task 3 At-Risk VIP & Task 4 Deadstock Net Recovery)
#                        to Part 3's Knowledge Catalog Ontology Layer.
# =============================================================================

view: order_items {
  sql_table_name: `yukoga-sandbox-001.thelook_soap.order_items` ;;
  label: "注文明細 (Order Items)"

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }

  dimension: order_id {
    type: number
    sql: ${TABLE}.order_id ;;
  }

  dimension: user_id {
    type: number
    sql: ${TABLE}.user_id ;;
  }

  dimension: product_id {
    type: number
    sql: ${TABLE}.product_id ;;
  }

  dimension: status {
    type: string
    description: "注文明細ステータス（Complete, Cancelled, Returned, Processing, Shipped）"
    sql: ${TABLE}.status ;;
  }

  dimension_group: created {
    type: time
    timeframes: [raw, date, month, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.created_at ;;
  }

  dimension: sale_price {
    type: number
    sql: ${TABLE}.sale_price ;;
  }

  # --- Semantic Measures for Task 1 (Valid Completed Sales & Gross Margin) ---
  measure: valid_order_count {
    label: "有効注文数 (Valid Completed Orders)"
    description: "ステータスが Complete（完了）の有効注文のユニーク注文数"
    type: count_distinct
    sql: ${order_id} ;;
    filters: [status: "Complete"]
  }

  measure: valid_item_count {
    label: "有効販売アイテム数 (Valid Completed Items)"
    description: "ステータスが Complete（完了）の有効注文明細のアイテム数"
    type: count
    filters: [status: "Complete"]
  }

  measure: gross_catalog_revenue {
    label: "カタログ売上総額 (Gross Catalog Revenue)"
    description: "ステータスが Complete（完了）の有効注文明細における販売価格合計（USD・小数第2位丸め）"
    type: sum
    sql: ${sale_price} ;;
    filters: [status: "Complete"]
    value_format_name: usd
  }

  measure: total_cost_of_goods_sold {
    label: "総原価 (Total Cost of Goods Sold)"
    description: "ステータスが Complete（完了）の有効注文明細に紐づく商品の標準仕入原価合計（USD・小数第2位丸め）"
    type: sum
    sql: ${products.cost} ;;
    filters: [status: "Complete"]
    value_format_name: usd
  }

  measure: gross_margin {
    label: "売上総利益 (Gross Margin)"
    description: "有効注文明細（status = Complete）におけるカタログ売上総額から総原価を差し引いた売上総利益（粗利・USD）"
    type: sum
    sql: ${sale_price} - ${products.cost} ;;
    filters: [status: "Complete"]
    value_format_name: usd
  }
}

view: products {
  sql_table_name: `yukoga-sandbox-001.thelook_soap.products` ;;
  label: "商品マスタ (Products)"

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }

  dimension: category {
    type: string
    sql: ${TABLE}.category ;;
  }

  dimension: department {
    type: string
    sql: ${TABLE}.department ;;
  }

  dimension: cost {
    type: number
    sql: ${TABLE}.cost ;;
  }

  dimension: retail_price {
    type: number
    sql: ${TABLE}.retail_price ;;
  }

  dimension: distribution_center_id {
    type: number
    sql: ${TABLE}.distribution_center_id ;;
  }
}

view: orders {
  sql_table_name: `yukoga-sandbox-001.thelook_soap.orders` ;;
  label: "注文ヘッダ (Orders)"

  dimension: order_id {
    primary_key: yes
    type: number
    sql: ${TABLE}.order_id ;;
  }

  dimension: user_id {
    type: number
    sql: ${TABLE}.user_id ;;
  }

  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
  }
}

view: users {
  sql_table_name: `yukoga-sandbox-001.thelook_soap.users` ;;
  label: "顧客マスタ (Users)"

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }

  dimension: country {
    type: string
    sql: ${TABLE}.country ;;
  }
}

view: distribution_centers {
  sql_table_name: `yukoga-sandbox-001.thelook_soap.distribution_centers` ;;
  label: "物流センター (Distribution Centers)"

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }

  dimension: name {
    label: "物流センター名"
    type: string
    sql: ${TABLE}.name ;;
  }
}

view: inventory_items {
  sql_table_name: `yukoga-sandbox-001.thelook_soap.inventory_items` ;;
  label: "在庫ユニット (Inventory Items)"

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }

  dimension: product_id {
    type: number
    sql: ${TABLE}.product_id ;;
  }

  dimension: product_distribution_center_id {
    type: number
    sql: ${TABLE}.product_distribution_center_id ;;
  }

  dimension: product_department {
    label: "商品部門"
    type: string
    sql: ${TABLE}.product_department ;;
  }

  dimension: is_unsold {
    label: "未販売フラグ (Unsold Stock Flag)"
    type: yesno
    sql: ${TABLE}.sold_at IS NULL ;;
  }

  dimension: days_in_inventory {
    label: "在庫滞留日数 (基準日 2025-01-01)"
    type: number
    sql: DATE_DIFF(DATE '2025-01-01', DATE(${TABLE}.created_at), DAY) ;;
  }

  # --- Semantic Measures for Task 2 (Unsold Warehouse Inventory Summary) ---
  measure: unsold_unit_count {
    label: "未販売在庫数 (Unsold Inventory Units)"
    description: "sold_at IS NULL の未販売物理在庫ユニット数"
    type: count
    filters: [is_unsold: "yes"]
  }

  measure: unsold_retail_value {
    label: "未販売定価総額 (Unsold Total Retail Value)"
    description: "sold_at IS NULL の未販売在庫におけるカタログ定価合計（USD）"
    type: sum
    sql: ${TABLE}.product_retail_price ;;
    filters: [is_unsold: "yes"]
    value_format_name: usd
  }

  measure: unsold_cost_value {
    label: "未販売原価総額 (Unsold Total Cost Value)"
    description: "sold_at IS NULL の未販売在庫における仕入原価合計（USD）"
    type: sum
    sql: ${TABLE}.cost ;;
    filters: [is_unsold: "yes"]
    value_format_name: usd
  }

  measure: avg_days_in_inventory {
    label: "平均在庫滞留日数 (Average Days in Inventory as of 2025-01-01)"
    description: "sold_at IS NULL の未販売在庫における入庫日から基準日 2025-01-01 までの平均滞留日数"
    type: average
    sql: ${days_in_inventory} ;;
    filters: [is_unsold: "yes"]
    value_format_name: decimal_2
  }
}
