# =============================================================================
# Part 2-1: Looker (Google Cloud Core) Semantic Layer Model Definition
# Looker Core Instance : https://looker001.yukoga.demo.altostrat.com/
# Target BigQuery      : yukoga-sandbox-001.thelook_soap
# Knowledge Catalog    : Automatic sync via --catalog-integration-enabled
# =============================================================================

connection: "default_bigquery_connection"

include: "/views/*.view.lkml"

datagroup: thelook_soap_default_datagroup {
  sql_trigger: SELECT MAX(created_at) FROM `yukoga-sandbox-001.thelook_soap.order_items` ;;
  max_cache_age: "24 hours"
}

persist_with: thelook_soap_default_datagroup

# Explore 1: Sales, Orders, and Gross Margin Semantic Model (Resolves Task 1)
explore: order_items {
  label: "TheLook SOAP 注文・売上・粗利分析 (Sales & Gross Margin)"
  description: "2023年等の年次・月次業績（有効注文数・有効販売アイテム数・カタログ売上総額・総原価・売上総利益）を集計する標準 Explore。"

  join: orders {
    type: inner
    relationship: many_to_one
    sql_on: ${order_items.order_id} = ${orders.order_id} ;;
  }

  join: products {
    type: inner
    relationship: many_to_one
    sql_on: ${order_items.product_id} = ${products.id} ;;
  }

  join: users {
    type: inner
    relationship: many_to_one
    sql_on: ${order_items.user_id} = ${users.id} ;;
  }

  join: distribution_centers {
    type: left_outer
    relationship: many_to_one
    sql_on: ${products.distribution_center_id} = ${distribution_centers.id} ;;
  }
}

# Explore 2: Warehouse Inventory Semantic Model (Resolves Task 2)
explore: inventory_items {
  label: "TheLook SOAP 物流センター別 在庫分析 (Warehouse Inventory)"
  description: "物流センター別の未販売在庫数・未販売定価総額・未販売原価総額・平均在庫滞留日数（基準日 2025-01-01）を集計する標準 Explore。"

  join: distribution_centers {
    type: inner
    relationship: many_to_one
    sql_on: ${inventory_items.product_distribution_center_id} = ${distribution_centers.id} ;;
  }

  join: products {
    type: left_outer
    relationship: many_to_one
    sql_on: ${inventory_items.product_id} = ${products.id} ;;
  }
}
