-- Drop existing types if they exist
DO $$ 
BEGIN
  -- Drop existing enum types if they exist
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    DROP TYPE user_role CASCADE;
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'file_type') THEN
    DROP TYPE file_type CASCADE;
  END IF;

  -- Recreate types
  CREATE TYPE user_role AS ENUM ('taller', 'admin', 'proveedor', 'contador');
  CREATE TYPE file_type AS ENUM ('accident_proof', 'invoice', 'counter_receipt');
END $$;

-- Drop existing tables if they exist
DROP TABLE IF EXISTS part_history CASCADE;
DROP TABLE IF EXISTS part_files CASCADE;
DROP TABLE IF EXISTS parts CASCADE;
DROP TABLE IF EXISTS providers CASCADE;
DROP TABLE IF EXISTS units CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- Now we can safely recreate the tables
CREATE TABLE profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  role user_role NOT NULL,
  name text NOT NULL CHECK (length(name) > 0),
  email text NOT NULL CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
  is_approved boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id),
  UNIQUE(email)
);

CREATE TABLE units (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE providers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(email)
);

CREATE TABLE parts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_id uuid REFERENCES units NOT NULL,
  provider_id uuid REFERENCES providers,
  status integer DEFAULT 0,
  description text[] NOT NULL,
  price decimal(10,2),
  unitary_price decimal(10,2)[],
  quantity integer[],
  is_cash boolean DEFAULT false,
  is_important boolean DEFAULT false,
  disposal_location text,
  failure_report jsonb,
  work_order jsonb,
  mechanic_review jsonb,
  invoice_info jsonb,
  req_date timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

CREATE TABLE part_files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  part_id uuid REFERENCES parts ON DELETE CASCADE,
  file_type file_type NOT NULL,
  file_path text NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE part_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  part_id uuid REFERENCES parts ON DELETE CASCADE,
  old_status int,
  new_status int,
  changed_by uuid REFERENCES auth.users,
  changed_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE units ENABLE ROW LEVEL SECURITY;
ALTER TABLE providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE part_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE part_history ENABLE ROW LEVEL SECURITY;
