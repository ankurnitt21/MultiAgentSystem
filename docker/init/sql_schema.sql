-- ============================================================================
-- SQL/Warehouse Database Schema (warehouse_db)
-- ============================================================================

-- === WAREHOUSE & STORAGE ===
CREATE TABLE warehouse (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    city VARCHAR(50),
    state VARCHAR(50),
    capacity_sqft NUMERIC(12,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE zone (
    id BIGSERIAL PRIMARY KEY,
    warehouse_id BIGINT NOT NULL REFERENCES warehouse(id),
    code VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    zone_type VARCHAR(30) NOT NULL,
    temperature_controlled BOOLEAN DEFAULT FALSE,
    max_capacity_units INTEGER,
    utilization_pct NUMERIC(5,2) DEFAULT 0,
    UNIQUE(warehouse_id, code)
);

CREATE TABLE location (
    id BIGSERIAL PRIMARY KEY,
    zone_id BIGINT NOT NULL REFERENCES zone(id),
    aisle VARCHAR(10),
    rack VARCHAR(10),
    shelf VARCHAR(10),
    bin VARCHAR(10),
    barcode VARCHAR(50) UNIQUE,
    location_type VARCHAR(30) NOT NULL,
    max_weight_kg NUMERIC(10,2),
    is_occupied BOOLEAN DEFAULT FALSE
);

-- === PRODUCT & CATALOG ===
CREATE TABLE category (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    parent_category_id BIGINT REFERENCES category(id),
    description TEXT
);

CREATE TABLE supplier (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    contact_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(30),
    city VARCHAR(50),
    country VARCHAR(50),
    lead_time_days INTEGER DEFAULT 7,
    rating NUMERIC(3,2)
);

CREATE TABLE product (
    id BIGSERIAL PRIMARY KEY,
    sku VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category_id BIGINT REFERENCES category(id),
    supplier_id BIGINT REFERENCES supplier(id),
    unit_price NUMERIC(12,2),
    cost_price NUMERIC(12,2),
    weight_kg NUMERIC(10,3),
    uom VARCHAR(20) DEFAULT 'EACH',
    is_perishable BOOLEAN DEFAULT FALSE,
    min_stock_level INTEGER DEFAULT 0,
    reorder_point INTEGER DEFAULT 0,
    reorder_qty INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- === INVENTORY ===
CREATE TABLE inventory (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES product(id),
    location_id BIGINT NOT NULL REFERENCES location(id),
    quantity_on_hand INTEGER NOT NULL DEFAULT 0,
    quantity_reserved INTEGER NOT NULL DEFAULT 0,
    quantity_available INTEGER GENERATED ALWAYS AS (quantity_on_hand - quantity_reserved) STORED,
    lot_number VARCHAR(50),
    expiry_date DATE,
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(product_id, location_id, lot_number)
);

CREATE TABLE inventory_transaction (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES product(id),
    from_location_id BIGINT REFERENCES location(id),
    to_location_id BIGINT REFERENCES location(id),
    transaction_type VARCHAR(30) NOT NULL,
    quantity INTEGER NOT NULL,
    reference_type VARCHAR(30),
    reference_id BIGINT,
    performed_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

-- === PROCUREMENT ===
CREATE TABLE purchase_order (
    id BIGSERIAL PRIMARY KEY,
    po_number VARCHAR(30) UNIQUE NOT NULL,
    supplier_id BIGINT NOT NULL REFERENCES supplier(id),
    warehouse_id BIGINT NOT NULL REFERENCES warehouse(id),
    status VARCHAR(20) DEFAULT 'DRAFT',
    order_date DATE,
    expected_delivery DATE,
    total_amount NUMERIC(14,2),
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE purchase_order_line (
    id BIGSERIAL PRIMARY KEY,
    purchase_order_id BIGINT NOT NULL REFERENCES purchase_order(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES product(id),
    quantity_ordered INTEGER NOT NULL,
    quantity_received INTEGER DEFAULT 0,
    unit_price NUMERIC(12,2)
);

-- === SALES & FULFILLMENT ===
CREATE TABLE customer (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(30),
    city VARCHAR(50),
    state VARCHAR(50),
    customer_type VARCHAR(30),
    credit_limit NUMERIC(14,2),
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE sales_order (
    id BIGSERIAL PRIMARY KEY,
    order_number VARCHAR(30) UNIQUE NOT NULL,
    customer_id BIGINT NOT NULL REFERENCES customer(id),
    warehouse_id BIGINT NOT NULL REFERENCES warehouse(id),
    status VARCHAR(20) DEFAULT 'PENDING',
    priority VARCHAR(10) DEFAULT 'NORMAL',
    order_date DATE,
    required_date DATE,
    total_amount NUMERIC(14,2),
    shipping_method VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE sales_order_line (
    id BIGSERIAL PRIMARY KEY,
    sales_order_id BIGINT NOT NULL REFERENCES sales_order(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES product(id),
    quantity_ordered INTEGER NOT NULL,
    quantity_shipped INTEGER DEFAULT 0,
    unit_price NUMERIC(12,2)
);

CREATE TABLE shipment (
    id BIGSERIAL PRIMARY KEY,
    shipment_number VARCHAR(30) UNIQUE NOT NULL,
    sales_order_id BIGINT NOT NULL REFERENCES sales_order(id),
    carrier VARCHAR(100),
    tracking_number VARCHAR(100),
    status VARCHAR(20) DEFAULT 'PENDING',
    shipped_date TIMESTAMP,
    delivered_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- === APP TABLES ===
CREATE TABLE schema_description (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    column_name VARCHAR(100),
    domain VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    data_type VARCHAR(50),
    embedding_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE conversation (
    id BIGSERIAL PRIMARY KEY,
    session_id VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    sql_query TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE conversation_summary (
    session_id VARCHAR(100) PRIMARY KEY,
    summary TEXT NOT NULL,
    approximate_tokens INTEGER DEFAULT 0,
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE query_feedback (
    id BIGSERIAL PRIMARY KEY,
    session_id VARCHAR(100) NOT NULL,
    run_id VARCHAR(100),
    query TEXT NOT NULL,
    generated_sql TEXT,
    pipeline VARCHAR(20),
    rating INTEGER NOT NULL CHECK (rating IN (-1, 1)),
    comment TEXT,
    correction TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_conv_session ON conversation(session_id);
CREATE INDEX idx_schema_domain ON schema_description(domain);
CREATE INDEX idx_feedback_session ON query_feedback(session_id);
CREATE INDEX idx_feedback_rating ON query_feedback(rating);

CREATE INDEX idx_schema_fts ON schema_description
    USING gin(to_tsvector('english', description || ' ' || table_name || ' ' || COALESCE(column_name, '')));

-- === SCHEMA DESCRIPTIONS (for hybrid retrieval) ===
INSERT INTO schema_description (table_name, column_name, domain, description, data_type) VALUES
('warehouse', NULL, 'warehouse', 'Physical warehouse locations with capacity and active status', NULL),
('warehouse', 'code', 'warehouse', 'Unique warehouse identifier code like WH-EAST-01', 'VARCHAR(20)'),
('warehouse', 'capacity_sqft', 'warehouse', 'Total warehouse capacity in square feet', 'NUMERIC(12,2)'),
('zone', NULL, 'warehouse', 'Storage zones within warehouses: RECEIVING, STORAGE, PICKING, SHIPPING, COLD_STORAGE, HAZMAT', NULL),
('zone', 'utilization_pct', 'warehouse', 'Current utilization percentage of the zone', 'NUMERIC(5,2)'),
('location', NULL, 'warehouse', 'Physical storage locations (bins, racks, shelves) within zones', NULL),
('product', NULL, 'product', 'Product catalog with SKU, pricing, weight, and reorder settings', NULL),
('product', 'unit_price', 'product', 'Selling price per unit of the product', 'NUMERIC(12,2)'),
('product', 'cost_price', 'product', 'Purchase/cost price from supplier', 'NUMERIC(12,2)'),
('product', 'reorder_point', 'product', 'Inventory level that triggers reorder', 'INTEGER'),
('category', NULL, 'product', 'Product categories with hierarchical parent-child relationships', NULL),
('supplier', NULL, 'procurement', 'Suppliers with contact info, lead time, and performance rating', NULL),
('supplier', 'lead_time_days', 'procurement', 'Average days for supplier to deliver orders', 'INTEGER'),
('supplier', 'rating', 'procurement', 'Supplier performance rating from 0.00 to 5.00', 'NUMERIC(3,2)'),
('inventory', NULL, 'inventory', 'Current stock levels per product per location with lot tracking', NULL),
('inventory', 'quantity_on_hand', 'inventory', 'Total physical quantity in stock at location', 'INTEGER'),
('inventory', 'quantity_reserved', 'inventory', 'Quantity reserved for pending orders', 'INTEGER'),
('inventory', 'quantity_available', 'inventory', 'Available quantity (on_hand - reserved), computed column', 'INTEGER'),
('inventory_transaction', NULL, 'inventory', 'Audit trail of all inventory movements: RECEIPT, PICK, TRANSFER, ADJUSTMENT, RETURN', NULL),
('purchase_order', NULL, 'procurement', 'Purchase orders to suppliers with status: DRAFT, SUBMITTED, CONFIRMED, RECEIVED, CANCELLED', NULL),
('purchase_order', 'total_amount', 'procurement', 'Total monetary value of the purchase order', 'NUMERIC(14,2)'),
('purchase_order_line', NULL, 'procurement', 'Line items in purchase orders with ordered vs received quantities', NULL),
('customer', NULL, 'sales', 'Customer accounts: RETAIL, WHOLESALE, DISTRIBUTOR with credit limits', NULL),
('sales_order', NULL, 'sales', 'Customer sales orders with status: PENDING, CONFIRMED, PICKING, SHIPPED, DELIVERED, CANCELLED', NULL),
('sales_order', 'priority', 'sales', 'Order priority: LOW, NORMAL, HIGH, URGENT', 'VARCHAR(10)'),
('sales_order', 'total_amount', 'sales', 'Total monetary value of the sales order', 'NUMERIC(14,2)'),
('sales_order_line', NULL, 'sales', 'Line items in sales orders with ordered vs shipped quantities', NULL),
('shipment', NULL, 'sales', 'Shipment tracking for sales orders with carrier and delivery info', NULL),
('shipment', 'status', 'sales', 'Shipment status: PENDING, IN_TRANSIT, DELIVERED', 'VARCHAR(20)'),
-- Enhanced: table-level and column-level descriptions with size/type details
('warehouse', 'id', 'warehouse', 'Auto-increment primary key for warehouse table', 'BIGSERIAL'),
('warehouse', 'name', 'warehouse', 'Full name of the warehouse facility', 'VARCHAR(100)'),
('warehouse', 'city', 'warehouse', 'City where warehouse is located', 'VARCHAR(50)'),
('warehouse', 'state', 'warehouse', 'US state abbreviation of warehouse location', 'VARCHAR(50)'),
('warehouse', 'is_active', 'warehouse', 'Whether warehouse is currently operational', 'BOOLEAN'),
('zone', 'id', 'warehouse', 'Auto-increment primary key for zone', 'BIGSERIAL'),
('zone', 'warehouse_id', 'warehouse', 'FK to warehouse.id - which warehouse this zone belongs to', 'BIGINT'),
('zone', 'code', 'warehouse', 'Short zone code like RCV-01 STR-01 unique per warehouse', 'VARCHAR(20)'),
('zone', 'zone_type', 'warehouse', 'Type: RECEIVING, STORAGE, PICKING, SHIPPING, COLD_STORAGE, HAZMAT', 'VARCHAR(30)'),
('zone', 'temperature_controlled', 'warehouse', 'Whether zone has temperature control for perishables', 'BOOLEAN'),
('zone', 'max_capacity_units', 'warehouse', 'Maximum number of storage units in this zone', 'INTEGER'),
('location', 'id', 'warehouse', 'Auto-increment primary key for location', 'BIGSERIAL'),
('location', 'zone_id', 'warehouse', 'FK to zone.id - which zone this location belongs to', 'BIGINT'),
('location', 'aisle', 'warehouse', 'Aisle identifier within the zone (A, B, C...)', 'VARCHAR(10)'),
('location', 'rack', 'warehouse', 'Rack number within the aisle', 'VARCHAR(10)'),
('location', 'shelf', 'warehouse', 'Shelf position on the rack', 'VARCHAR(10)'),
('location', 'bin', 'warehouse', 'Bin position on the shelf', 'VARCHAR(10)'),
('location', 'barcode', 'warehouse', 'Unique scannable barcode for physical location', 'VARCHAR(50)'),
('location', 'location_type', 'warehouse', 'Type: RACK, BULK, PALLET, PICK_FACE, FLOOR', 'VARCHAR(30)'),
('location', 'max_weight_kg', 'warehouse', 'Maximum weight capacity in kilograms', 'NUMERIC(10,2)'),
('location', 'is_occupied', 'warehouse', 'Whether location currently has inventory', 'BOOLEAN'),
('product', 'id', 'product', 'Auto-increment primary key for product', 'BIGSERIAL'),
('product', 'sku', 'product', 'Unique Stock Keeping Unit code like SKU-LAPTOP-001', 'VARCHAR(50)'),
('product', 'name', 'product', 'Product display name', 'VARCHAR(200)'),
('product', 'description', 'product', 'Detailed product description text', 'TEXT'),
('product', 'category_id', 'product', 'FK to category.id - product category', 'BIGINT'),
('product', 'supplier_id', 'product', 'FK to supplier.id - primary supplier for this product', 'BIGINT'),
('product', 'weight_kg', 'product', 'Product weight in kilograms', 'NUMERIC(10,3)'),
('product', 'uom', 'product', 'Unit of measure: EACH, BOX, PALLET, KG', 'VARCHAR(20)'),
('product', 'is_perishable', 'product', 'Whether product has expiry date tracking', 'BOOLEAN'),
('product', 'min_stock_level', 'product', 'Minimum stock threshold before alert', 'INTEGER'),
('product', 'reorder_qty', 'product', 'Standard quantity to reorder', 'INTEGER'),
('product', 'is_active', 'product', 'Whether product is currently sold/stocked', 'BOOLEAN'),
('category', 'id', 'product', 'Auto-increment primary key for category', 'BIGSERIAL'),
('category', 'name', 'product', 'Category name: Electronics, Furniture, Safety, Packaging, Food', 'VARCHAR(100)'),
('category', 'parent_category_id', 'product', 'FK to category.id for hierarchical categories', 'BIGINT'),
('supplier', 'id', 'procurement', 'Auto-increment primary key for supplier', 'BIGSERIAL'),
('supplier', 'code', 'procurement', 'Unique supplier code like SUP-TECH', 'VARCHAR(20)'),
('supplier', 'name', 'procurement', 'Full supplier company name', 'VARCHAR(150)'),
('supplier', 'contact_name', 'procurement', 'Primary contact person at supplier', 'VARCHAR(100)'),
('supplier', 'email', 'procurement', 'Supplier email address', 'VARCHAR(100)'),
('supplier', 'phone', 'procurement', 'Supplier phone number', 'VARCHAR(30)'),
('supplier', 'city', 'procurement', 'Supplier city', 'VARCHAR(50)'),
('supplier', 'country', 'procurement', 'Supplier country', 'VARCHAR(50)'),
('inventory', 'id', 'inventory', 'Auto-increment primary key for inventory', 'BIGSERIAL'),
('inventory', 'product_id', 'inventory', 'FK to product.id - which product', 'BIGINT'),
('inventory', 'location_id', 'inventory', 'FK to location.id - where stored', 'BIGINT'),
('inventory', 'lot_number', 'inventory', 'Lot/batch tracking number', 'VARCHAR(50)'),
('inventory', 'expiry_date', 'inventory', 'Expiration date for perishable items', 'DATE'),
('inventory_transaction', 'id', 'inventory', 'Auto-increment primary key', 'BIGSERIAL'),
('inventory_transaction', 'product_id', 'inventory', 'FK to product.id', 'BIGINT'),
('inventory_transaction', 'from_location_id', 'inventory', 'FK to location.id source (NULL for receipts)', 'BIGINT'),
('inventory_transaction', 'to_location_id', 'inventory', 'FK to location.id destination (NULL for picks)', 'BIGINT'),
('inventory_transaction', 'transaction_type', 'inventory', 'Type: RECEIPT, PICK, TRANSFER, ADJUSTMENT, RETURN', 'VARCHAR(30)'),
('inventory_transaction', 'quantity', 'inventory', 'Quantity moved (negative for adjustments down)', 'INTEGER'),
('inventory_transaction', 'reference_type', 'inventory', 'Source: PURCHASE_ORDER, SALES_ORDER, ADJUSTMENT', 'VARCHAR(30)'),
('inventory_transaction', 'performed_by', 'inventory', 'User who performed the transaction', 'VARCHAR(100)'),
('purchase_order', 'id', 'procurement', 'Auto-increment primary key', 'BIGSERIAL'),
('purchase_order', 'po_number', 'procurement', 'Unique PO number like PO-2024-001', 'VARCHAR(30)'),
('purchase_order', 'supplier_id', 'procurement', 'FK to supplier.id', 'BIGINT'),
('purchase_order', 'warehouse_id', 'procurement', 'FK to warehouse.id - receiving warehouse', 'BIGINT'),
('purchase_order', 'status', 'procurement', 'PO status: DRAFT, SUBMITTED, CONFIRMED, RECEIVED, CANCELLED', 'VARCHAR(20)'),
('purchase_order', 'order_date', 'procurement', 'Date PO was placed', 'DATE'),
('purchase_order', 'expected_delivery', 'procurement', 'Expected delivery date from supplier', 'DATE'),
('purchase_order', 'created_by', 'procurement', 'User who created the PO', 'VARCHAR(100)'),
('purchase_order_line', 'id', 'procurement', 'Auto-increment primary key', 'BIGSERIAL'),
('purchase_order_line', 'purchase_order_id', 'procurement', 'FK to purchase_order.id', 'BIGINT'),
('purchase_order_line', 'product_id', 'procurement', 'FK to product.id', 'BIGINT'),
('purchase_order_line', 'quantity_ordered', 'procurement', 'Quantity ordered from supplier', 'INTEGER'),
('purchase_order_line', 'quantity_received', 'procurement', 'Quantity actually received so far', 'INTEGER'),
('purchase_order_line', 'unit_price', 'procurement', 'Price per unit on this PO line', 'NUMERIC(12,2)'),
('customer', 'id', 'sales', 'Auto-increment primary key', 'BIGSERIAL'),
('customer', 'code', 'sales', 'Unique customer code like CUST-001', 'VARCHAR(20)'),
('customer', 'name', 'sales', 'Full customer/company name', 'VARCHAR(150)'),
('customer', 'email', 'sales', 'Customer email', 'VARCHAR(100)'),
('customer', 'phone', 'sales', 'Customer phone', 'VARCHAR(30)'),
('customer', 'city', 'sales', 'Customer city', 'VARCHAR(50)'),
('customer', 'state', 'sales', 'Customer US state', 'VARCHAR(50)'),
('customer', 'customer_type', 'sales', 'Type: RETAIL, WHOLESALE, DISTRIBUTOR', 'VARCHAR(30)'),
('customer', 'credit_limit', 'sales', 'Maximum credit allowed for this customer', 'NUMERIC(14,2)'),
('customer', 'is_active', 'sales', 'Whether customer account is active', 'BOOLEAN'),
('sales_order', 'id', 'sales', 'Auto-increment primary key', 'BIGSERIAL'),
('sales_order', 'order_number', 'sales', 'Unique order number like SO-2024-001', 'VARCHAR(30)'),
('sales_order', 'customer_id', 'sales', 'FK to customer.id', 'BIGINT'),
('sales_order', 'warehouse_id', 'sales', 'FK to warehouse.id - fulfillment warehouse', 'BIGINT'),
('sales_order', 'status', 'sales', 'Order status: PENDING, CONFIRMED, PICKING, SHIPPED, DELIVERED, CANCELLED', 'VARCHAR(20)'),
('sales_order', 'order_date', 'sales', 'Date order was placed', 'DATE'),
('sales_order', 'required_date', 'sales', 'Customer requested delivery date', 'DATE'),
('sales_order', 'shipping_method', 'sales', 'Carrier method: UPS Ground, FedEx Express, USPS Priority', 'VARCHAR(50)'),
('sales_order_line', 'id', 'sales', 'Auto-increment primary key', 'BIGSERIAL'),
('sales_order_line', 'sales_order_id', 'sales', 'FK to sales_order.id', 'BIGINT'),
('sales_order_line', 'product_id', 'sales', 'FK to product.id', 'BIGINT'),
('sales_order_line', 'quantity_ordered', 'sales', 'Quantity customer ordered', 'INTEGER'),
('sales_order_line', 'quantity_shipped', 'sales', 'Quantity shipped so far', 'INTEGER'),
('sales_order_line', 'unit_price', 'sales', 'Selling price per unit', 'NUMERIC(12,2)'),
('shipment', 'id', 'sales', 'Auto-increment primary key', 'BIGSERIAL'),
('shipment', 'shipment_number', 'sales', 'Unique shipment number like SHP-001', 'VARCHAR(30)'),
('shipment', 'sales_order_id', 'sales', 'FK to sales_order.id', 'BIGINT'),
('shipment', 'carrier', 'sales', 'Shipping carrier: UPS, FedEx, USPS, DHL', 'VARCHAR(100)'),
('shipment', 'tracking_number', 'sales', 'Carrier tracking number', 'VARCHAR(100)'),
('shipment', 'shipped_date', 'sales', 'Timestamp when shipment was dispatched', 'TIMESTAMP'),
('shipment', 'delivered_date', 'sales', 'Timestamp when shipment was delivered', 'TIMESTAMP');

-- === SEED DATA ===
INSERT INTO warehouse (code, name, city, state, capacity_sqft) VALUES
('WH-EAST-01', 'East Coast Distribution Center', 'Newark', 'NJ', 250000),
('WH-WEST-01', 'West Coast Fulfillment Hub', 'Ontario', 'CA', 320000),
('WH-CENT-01', 'Central Regional Warehouse', 'Dallas', 'TX', 180000);

INSERT INTO zone (warehouse_id, code, name, zone_type, max_capacity_units, utilization_pct) VALUES
(1, 'RCV-01', 'Receiving Dock', 'RECEIVING', 5000, 45),
(1, 'STR-01', 'General Storage A', 'STORAGE', 50000, 72),
(1, 'STR-02', 'Cold Storage', 'COLD_STORAGE', 10000, 55),
(1, 'PCK-01', 'Picking Zone', 'PICKING', 8000, 60),
(1, 'SHP-01', 'Shipping Dock', 'SHIPPING', 3000, 35),
(2, 'STR-01', 'Main Storage', 'STORAGE', 80000, 78),
(2, 'PCK-01', 'Pick & Pack', 'PICKING', 12000, 65),
(3, 'STR-01', 'Primary Storage', 'STORAGE', 40000, 82),
(2, 'RCV-01', 'West Receiving', 'RECEIVING', 4000, 50),
(3, 'PCK-01', 'Central Picking', 'PICKING', 6000, 70),
(1, 'HAZ-01', 'Hazmat Storage', 'HAZMAT', 2000, 30);

INSERT INTO location (zone_id, aisle, rack, shelf, bin, barcode, location_type, max_weight_kg, is_occupied) VALUES
(2, 'A', '01', '01', '01', 'LOC-A010101', 'RACK', 500, TRUE),
(2, 'A', '01', '02', '01', 'LOC-A010201', 'RACK', 500, TRUE),
(2, 'A', '02', '01', '01', 'LOC-A020101', 'RACK', 500, FALSE),
(2, 'B', '01', '01', '01', 'LOC-B010101', 'BULK', 2000, TRUE),
(3, 'F', '01', '01', '01', 'LOC-F010101', 'RACK', 400, TRUE),
(4, 'P', '01', '01', '01', 'LOC-P010101', 'PICK_FACE', 200, TRUE),
(6, 'A', '01', '01', '01', 'LOC-W-A0101', 'RACK', 600, TRUE),
(6, 'B', '01', '01', '01', 'LOC-W-B0101', 'PALLET', 1200, TRUE),
(8, 'A', '01', '01', '01', 'LOC-C-A0101', 'RACK', 500, TRUE),
(2, 'C', '01', '01', '01', 'LOC-C010101', 'RACK', 500, TRUE),
(2, 'C', '02', '01', '01', 'LOC-C020101', 'RACK', 500, TRUE),
(6, 'C', '01', '01', '01', 'LOC-W-C0101', 'RACK', 600, FALSE),
(9, 'A', '01', '01', '01', 'LOC-WR-A0101', 'FLOOR', 3000, TRUE),
(10, 'A', '01', '01', '01', 'LOC-CP-A0101', 'PICK_FACE', 200, TRUE);

INSERT INTO category (name, description) VALUES
('Electronics', 'Electronic devices and accessories'),
('Furniture', 'Office and warehouse furniture'),
('Safety Equipment', 'PPE and safety gear'),
('Packaging', 'Boxes, wrap, and shipping supplies'),
('Food & Beverage', 'Perishable and non-perishable items');

INSERT INTO supplier (code, name, contact_name, email, phone, city, country, lead_time_days, rating) VALUES
('SUP-TECH', 'TechWave Electronics', 'David Park', 'david@techwave.com', '408-555-0101', 'San Jose', 'USA', 5, 4.50),
('SUP-FURN', 'OfficeMax Furniture', 'Rachel Green', 'rachel@officemax.com', '616-555-0202', 'Grand Rapids', 'USA', 14, 4.20),
('SUP-SAFE', 'SafeGuard Industries', 'Tom Bradley', 'tom@safeguard.com', '513-555-0303', 'Cincinnati', 'USA', 7, 4.80),
('SUP-PACK', 'PackRight Solutions', 'Nina Patel', 'nina@packright.com', '901-555-0404', 'Memphis', 'USA', 3, 4.60),
('SUP-FOOD', 'FreshChain Foods', 'Amy Wu', 'amy@freshchain.com', '503-555-0505', 'Portland', 'USA', 2, 4.70),
('SUP-IND', 'Industrial Parts Co', 'Mark Johnson', 'mark@indparts.com', '312-555-0606', 'Chicago', 'USA', 10, 3.90),
('SUP-CLEAN', 'CleanPro Supplies', 'Lisa Chen', 'lisa@cleanpro.com', '213-555-0707', 'Los Angeles', 'USA', 4, 4.30);

INSERT INTO product (sku, name, description, category_id, supplier_id, unit_price, cost_price, weight_kg, uom, min_stock_level, reorder_point, reorder_qty) VALUES
('SKU-LAPTOP-001', 'ProBook Laptop 15"', 'Business laptop 16GB RAM 512GB SSD', 1, 1, 899.99, 650, 2.1, 'EACH', 50, 100, 200),
('SKU-TABLET-001', 'SmartTab Pro 10"', '10-inch tablet with stylus 128GB', 1, 1, 499.99, 320, 0.55, 'EACH', 30, 60, 100),
('SKU-CABLE-001', 'Cat6 Ethernet Cable 10ft', 'Network cable RJ45 1Gbps', 1, 1, 12.99, 4.5, 0.15, 'EACH', 200, 500, 1000),
('SKU-DESK-001', 'Ergonomic Standing Desk', 'Electric height-adjustable 60x30 inch', 2, 2, 549.99, 320, 35, 'EACH', 10, 20, 50),
('SKU-CHAIR-001', 'Executive Mesh Chair', 'Lumbar support ergonomic chair', 2, 2, 349.99, 180, 18, 'EACH', 15, 30, 60),
('SKU-HHAT-001', 'Hard Hat Type II White', 'ANSI Z89.1 certified protective helmet', 3, 3, 24.99, 8.5, 0.4, 'EACH', 100, 200, 500),
('SKU-VEST-001', 'Hi-Vis Safety Vest', 'Class 2 ANSI reflective vest', 3, 3, 14.99, 5, 0.2, 'EACH', 150, 300, 600),
('SKU-BOX-SM', 'Shipping Box Small', '12x10x8 corrugated single-wall', 4, 4, 1.99, 0.45, 0.3, 'EACH', 500, 1000, 3000),
('SKU-BOX-LG', 'Shipping Box Large', '24x18x18 heavy-duty double-wall', 4, 4, 5.99, 1.5, 0.8, 'EACH', 200, 500, 1500),
('SKU-CHICKEN', 'Frozen Chicken Breast 5lb', 'Boneless skinless premium grade', 5, 5, 12.99, 7.5, 2.27, 'EACH', 100, 200, 500),
('SKU-MONITOR-001', 'UltraWide Monitor 34"', 'Curved 34-inch IPS display 3440x1440', 1, 1, 699.99, 450, 8.5, 'EACH', 20, 40, 80),
('SKU-KEYBOARD-001', 'Wireless Mechanical Keyboard', 'Bluetooth backlit Cherry MX switches', 1, 1, 89.99, 38, 0.8, 'EACH', 50, 100, 200),
('SKU-MOUSE-001', 'Ergonomic Wireless Mouse', 'Vertical mouse 2.4GHz USB receiver', 1, 1, 34.99, 12, 0.12, 'EACH', 80, 150, 300),
('SKU-SHELF-001', 'Industrial Steel Shelving', '48x24x72 inch 5-tier 2000lb capacity', 2, 2, 189.99, 95, 45, 'EACH', 5, 10, 25),
('SKU-GLOVE-001', 'Nitrile Work Gloves Box/100', 'Powder-free disposable large', 3, 3, 18.99, 6.5, 0.5, 'BOX', 200, 400, 1000),
('SKU-TAPE-001', 'Packing Tape 6-Roll Pack', '2-inch wide clear shipping tape', 4, 4, 9.99, 3.2, 1.5, 'EACH', 300, 600, 1500),
('SKU-WRAP-001', 'Stretch Wrap 18" 1500ft', 'Clear stretch film pallet wrap', 4, 4, 24.99, 10, 4.5, 'EACH', 50, 100, 250),
('SKU-WATER-001', 'Bottled Water Case/24', 'Spring water 500ml bottles', 5, 5, 6.99, 3.5, 12, 'CASE', 200, 400, 1000),
('SKU-LABEL-001', 'Thermal Labels 4x6 Roll/500', 'Direct thermal shipping labels', 4, 4, 14.99, 5, 1.2, 'EACH', 100, 250, 500),
('SKU-HEADSET-001', 'USB-C Headset with Mic', 'Noise-cancelling business headset', 1, 1, 59.99, 22, 0.25, 'EACH', 40, 80, 160);

INSERT INTO inventory (product_id, location_id, quantity_on_hand, quantity_reserved, lot_number) VALUES
(1, 1, 120, 15, 'LOT-2024-001'),
(1, 2, 80, 10, 'LOT-2024-002'),
(2, 2, 200, 25, 'LOT-2024-003'),
(3, 4, 1500, 200, 'LOT-2024-004'),
(4, 4, 25, 3, 'LOT-2024-005'),
(5, 4, 40, 5, 'LOT-2024-006'),
(6, 6, 450, 50, 'LOT-2024-007'),
(7, 6, 600, 75, 'LOT-2024-008'),
(8, 6, 3000, 500, 'LOT-2024-009'),
(10, 5, 300, 40, 'LOT-FRZ-001'),
(1, 7, 90, 8, 'LOT-2024-010'),
(3, 8, 2500, 300, 'LOT-2024-011'),
(9, 9, 180, 25, 'LOT-2024-012'),
(11, 10, 35, 5, 'LOT-2024-013'),
(12, 10, 150, 20, 'LOT-2024-014'),
(13, 11, 250, 30, 'LOT-2024-015'),
(14, 4, 12, 2, 'LOT-2024-016'),
(15, 6, 800, 100, 'LOT-2024-017'),
(16, 6, 1200, 150, 'LOT-2024-018'),
(17, 6, 80, 10, 'LOT-2024-019'),
(18, 5, 450, 60, 'LOT-FRZ-002'),
(19, 6, 400, 50, 'LOT-2024-020'),
(20, 10, 120, 15, 'LOT-2024-021'),
(11, 1, 20, 0, 'LOT-2024-022'),
(2, 7, 100, 12, 'LOT-2024-023');

INSERT INTO customer (code, name, email, phone, city, state, customer_type, credit_limit) VALUES
('CUST-001', 'Metro Office Supplies', 'john@metrooffice.com', '212-555-1001', 'New York', 'NY', 'RETAIL', 50000),
('CUST-002', 'BulkBuy Distributors', 'maria@bulkbuy.com', '312-555-1002', 'Chicago', 'IL', 'WHOLESALE', 250000),
('CUST-003', 'Pacific Coast Trading', 'kevin@pctrade.com', '562-555-1003', 'Long Beach', 'CA', 'DISTRIBUTOR', 500000),
('CUST-004', 'GreenTech Solutions', 'priya@greentech.com', '512-555-1004', 'Austin', 'TX', 'RETAIL', 75000),
('CUST-005', 'Northeast Healthcare', 'sarah@nehc.com', '617-555-1005', 'Boston', 'MA', 'WHOLESALE', 150000),
('CUST-006', 'Midwest Manufacturing', 'bob@mwmfg.com', '614-555-1006', 'Columbus', 'OH', 'DISTRIBUTOR', 300000),
('CUST-007', 'SunState Retail Corp', 'carlos@sunstate.com', '305-555-1007', 'Miami', 'FL', 'RETAIL', 100000);

INSERT INTO purchase_order (po_number, supplier_id, warehouse_id, status, order_date, expected_delivery, total_amount, created_by) VALUES
('PO-2024-001', 1, 1, 'RECEIVED', '2024-08-01', '2024-08-10', 175000, 'admin'),
('PO-2024-002', 4, 1, 'RECEIVED', '2024-09-15', '2024-09-20', 12500, 'admin'),
('PO-2024-003', 5, 1, 'CONFIRMED', '2024-10-15', '2024-10-20', 8500, 'admin'),
('PO-2024-004', 2, 2, 'SUBMITTED', '2024-11-05', '2024-11-25', 45000, 'admin'),
('PO-2024-005', 1, 1, 'RECEIVED', '2024-06-01', '2024-06-08', 52000, 'admin'),
('PO-2024-006', 3, 1, 'RECEIVED', '2024-07-10', '2024-07-18', 9750, 'admin'),
('PO-2024-007', 4, 2, 'CONFIRMED', '2024-11-10', '2024-11-15', 7800, 'admin'),
('PO-2024-008', 1, 2, 'DRAFT', '2024-11-15', '2024-11-25', 89500, 'admin');

INSERT INTO purchase_order_line (purchase_order_id, product_id, quantity_ordered, quantity_received, unit_price) VALUES
(1, 1, 200, 200, 650), (1, 2, 100, 100, 320),
(2, 8, 3000, 3000, 0.45), (2, 9, 1000, 1000, 1.5),
(3, 10, 500, 300, 7.5), (4, 4, 50, 0, 320),
(5, 11, 40, 40, 450), (5, 12, 200, 200, 38),
(6, 6, 500, 500, 8.5), (6, 7, 600, 600, 5),
(7, 16, 1500, 0, 3.2), (7, 17, 100, 0, 10),
(8, 1, 100, 0, 650), (8, 11, 30, 0, 450);

INSERT INTO sales_order (order_number, customer_id, warehouse_id, status, priority, order_date, required_date, total_amount, shipping_method) VALUES
('SO-2024-001', 1, 1, 'DELIVERED', 'NORMAL', '2024-09-20', '2024-09-28', 4500, 'UPS Ground'),
('SO-2024-002', 2, 1, 'SHIPPED', 'HIGH', '2024-10-01', '2024-10-05', 32500, 'FedEx Freight'),
('SO-2024-003', 3, 2, 'PICKING', 'URGENT', '2024-11-01', '2024-11-04', 55000, 'FedEx Express'),
('SO-2024-004', 1, 1, 'PENDING', 'NORMAL', '2024-11-08', '2024-11-15', 2100, 'USPS Priority'),
('SO-2024-005', 5, 1, 'CONFIRMED', 'HIGH', '2024-11-10', '2024-11-14', 8500, 'UPS Express'),
('SO-2024-006', 2, 1, 'DELIVERED', 'NORMAL', '2024-08-15', '2024-08-22', 15000, 'FedEx Ground'),
('SO-2024-007', 6, 2, 'SHIPPED', 'NORMAL', '2024-10-20', '2024-10-28', 22000, 'UPS Ground'),
('SO-2024-008', 4, 1, 'PENDING', 'LOW', '2024-11-12', '2024-11-22', 3200, 'USPS Priority'),
('SO-2024-009', 7, 2, 'CONFIRMED', 'URGENT', '2024-11-13', '2024-11-16', 42000, 'FedEx Express'),
('SO-2024-010', 3, 2, 'DELIVERED', 'HIGH', '2024-07-01', '2024-07-08', 28000, 'FedEx Freight');

INSERT INTO sales_order_line (sales_order_id, product_id, quantity_ordered, quantity_shipped, unit_price) VALUES
(1, 1, 5, 5, 899.99), (2, 1, 25, 25, 899.99), (2, 3, 500, 500, 12.99),
(3, 1, 50, 0, 899.99), (3, 2, 30, 0, 499.99), (4, 6, 50, 0, 24.99),
(5, 11, 10, 0, 699.99), (5, 12, 10, 0, 89.99),
(6, 3, 800, 800, 12.99), (6, 8, 500, 500, 1.99),
(7, 4, 30, 30, 549.99), (7, 5, 20, 20, 349.99),
(8, 13, 50, 0, 34.99), (8, 12, 20, 0, 89.99),
(9, 1, 40, 0, 899.99), (9, 11, 10, 0, 699.99),
(10, 1, 20, 20, 899.99), (10, 2, 15, 15, 499.99);

INSERT INTO shipment (shipment_number, sales_order_id, carrier, tracking_number, status, shipped_date, delivered_date) VALUES
('SHP-001', 1, 'UPS', '1Z999AA10123456784', 'DELIVERED', '2024-09-25', '2024-09-27'),
('SHP-002', 2, 'FedEx', 'FX7890123456', 'IN_TRANSIT', '2024-10-03', NULL),
('SHP-003', 6, 'FedEx', 'FX7890123789', 'DELIVERED', '2024-08-18', '2024-08-21'),
('SHP-004', 7, 'UPS', '1Z999BB20234567895', 'IN_TRANSIT', '2024-10-23', NULL),
('SHP-005', 10, 'FedEx', 'FX7890124000', 'DELIVERED', '2024-07-03', '2024-07-06');

INSERT INTO inventory_transaction (product_id, from_location_id, to_location_id, transaction_type, quantity, reference_type, reference_id, performed_by, created_at) VALUES
(1, NULL, 1, 'RECEIPT', 120, 'PURCHASE_ORDER', 1, 'warehouse_ops', '2024-08-09 08:00:00'),
(1, 1, NULL, 'PICK', 5, 'SALES_ORDER', 1, 'picker_01', '2024-09-24 10:00:00'),
(1, 1, NULL, 'PICK', 25, 'SALES_ORDER', 2, 'picker_01', '2024-10-02 08:00:00'),
(3, NULL, 4, 'RECEIPT', 1500, 'PURCHASE_ORDER', 1, 'warehouse_ops', '2024-08-09 09:00:00'),
(8, NULL, 6, 'ADJUSTMENT', -50, 'ADJUSTMENT', NULL, 'supervisor', '2024-10-20 14:00:00'),
(11, NULL, 10, 'RECEIPT', 40, 'PURCHASE_ORDER', 5, 'warehouse_ops', '2024-06-08 08:00:00'),
(12, NULL, 10, 'RECEIPT', 200, 'PURCHASE_ORDER', 5, 'warehouse_ops', '2024-06-08 09:00:00'),
(6, NULL, 6, 'RECEIPT', 500, 'PURCHASE_ORDER', 6, 'warehouse_ops', '2024-07-18 08:00:00'),
(1, 1, 7, 'TRANSFER', 30, 'ADJUSTMENT', NULL, 'warehouse_ops', '2024-09-01 10:00:00'),
(3, 4, NULL, 'PICK', 800, 'SALES_ORDER', 6, 'picker_02', '2024-08-17 14:00:00'),
(4, NULL, 4, 'RECEIPT', 30, 'PURCHASE_ORDER', 4, 'warehouse_ops', '2024-11-06 08:00:00'),
(2, NULL, 7, 'RECEIPT', 100, 'PURCHASE_ORDER', 1, 'warehouse_ops', '2024-08-09 10:00:00');
