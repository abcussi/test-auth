-- init.sql
-- Create extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create enum types
CREATE TYPE gender_enum AS ENUM ('male', 'female', 'other');
CREATE TYPE item_type_enum AS ENUM ('Water', 'Food', 'Medication', 'C-Virus Vaccine');

-- Create items table
CREATE TABLE items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name item_type_enum NOT NULL,
    description TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create survivors table
CREATE TABLE survivors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    age INTEGER NOT NULL,
    gender gender_enum NOT NULL,
    latitude DECIMAL NOT NULL,
    longitude DECIMAL NOT NULL,
    infected BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create inventory table
CREATE TABLE inventory_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    survivor_id UUID REFERENCES survivors(id) ON DELETE CASCADE,
    item_id UUID REFERENCES items(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create trades table
CREATE TABLE trades (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    from_survivor_id UUID REFERENCES survivors(id),
    to_survivor_id UUID REFERENCES survivors(id),
    items_offered JSONB NOT NULL,
    items_requested JSONB NOT NULL,
    traded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create trades_log table for keeping track of all trades
CREATE TABLE trades_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trade_id UUID REFERENCES trades(id),
    log_message TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Insert initial items
INSERT INTO items (name, description) VALUES
    ('Water', 'Clean drinking water - essential for survival'),
    ('Food', 'Non-perishable food supplies'),
    ('Medication', 'Basic medical supplies and antibiotics'),
    ('C-Virus Vaccine', 'Experimental vaccine against the Cogni-Virus');

-- Create indexes
CREATE INDEX idx_survivors_infected ON survivors(infected);
CREATE INDEX idx_inventory_items_survivor_id ON inventory_items(survivor_id);
CREATE INDEX idx_trades_from_survivor ON trades(from_survivor_id);
CREATE INDEX idx_trades_to_survivor ON trades(to_survivor_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_survivors_updated_at
    BEFORE UPDATE ON survivors
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inventory_items_updated_at
    BEFORE UPDATE ON inventory_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();