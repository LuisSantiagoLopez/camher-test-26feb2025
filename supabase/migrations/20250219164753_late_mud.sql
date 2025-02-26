-- Drop existing trigger
DROP TRIGGER IF EXISTS tr_handle_part_status ON parts;
DROP FUNCTION IF EXISTS handle_part_status();

-- Create improved function to handle part status
CREATE OR REPLACE FUNCTION handle_part_status()
RETURNS TRIGGER AS $$
BEGIN
  -- For new parts or when price/payment type changes
  IF (TG_OP = 'INSERT' OR OLD.price IS DISTINCT FROM NEW.price OR OLD.is_cash IS DISTINCT FROM NEW.is_cash) THEN
    -- Set initial status based on conditions
    IF (NEW.is_cash AND NEW.price > 500) OR (NOT NEW.is_cash AND NEW.price > 10000) THEN
      NEW.status := 2; -- Admin review required
    ELSE
      NEW.status := 3; -- Direct to provider
    END IF;
  END IF;

  -- Validate status transitions
  IF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
    -- Allow cancellation from any status
    IF NEW.status = -1 THEN
      RETURN NEW;
    END IF;

    -- Prevent changes to cancelled parts
    IF OLD.status = -1 THEN
      RAISE EXCEPTION 'No se puede modificar una refacción cancelada';
    END IF;

    -- Validate status flow
    CASE OLD.status
      WHEN 0 THEN -- Initial/Rejected
        IF NEW.status NOT IN (1, 2, 3) THEN
          RAISE EXCEPTION 'Transición de estatus inválida desde estado inicial';
        END IF;
      WHEN 1 THEN -- Created
        IF NEW.status NOT IN (2, 3) THEN
          RAISE EXCEPTION 'Transición de estatus inválida desde creada';
        END IF;
      WHEN 2 THEN -- Admin Review
        IF NEW.status NOT IN (3, 0, -1) THEN
          RAISE EXCEPTION 'Transición de estatus inválida desde revisión de admin';
        END IF;
      WHEN 3 THEN -- Provider Review
        IF NEW.status NOT IN (4, 0, -1) THEN
          RAISE EXCEPTION 'Transición de estatus inválida desde revisión de proveedor';
        END IF;
      WHEN 4 THEN -- Awaiting Invoice
        IF NEW.status NOT IN (5, -1) THEN
          RAISE EXCEPTION 'Transición de estatus inválida desde espera de factura';
        END IF;
      WHEN 5 THEN -- Awaiting Counter Receipt
        IF NEW.status NOT IN (6, -1) THEN -- Allow transition to status 6
          RAISE EXCEPTION 'Transición de estatus inválida desde espera de contrarecibo';
        END IF;
      WHEN 6 THEN -- Completed
        IF NEW.status NOT IN (-1) THEN
          RAISE EXCEPTION 'Transición de estatus inválida desde completada';
        END IF;
      ELSE
        RAISE EXCEPTION 'Transición de estatus inválida de % a %', OLD.status, NEW.status;
    END CASE;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for status handling
CREATE TRIGGER tr_handle_part_status
  BEFORE INSERT OR UPDATE ON parts
  FOR EACH ROW
  EXECUTE FUNCTION handle_part_status();

-- Update function to get part status text
CREATE OR REPLACE FUNCTION get_part_status_text(status integer)
RETURNS text AS $$
BEGIN
  RETURN CASE status
    WHEN -1 THEN 'Cancelada'
    WHEN 0 THEN 'Inicial/Rechazada'
    WHEN 1 THEN 'Creada'
    WHEN 2 THEN 'Revisión Admin'
    WHEN 3 THEN 'Revisión Proveedor'
    WHEN 4 THEN 'Esperando Factura'
    WHEN 5 THEN 'Esperando Contrarecibo'
    WHEN 6 THEN 'Completada'
    ELSE 'Desconocido'
  END;
END;
$$ LANGUAGE plpgsql;

-- Add helpful comments
COMMENT ON FUNCTION handle_part_status IS 'Validates and manages part status transitions including completed state';
COMMENT ON FUNCTION get_part_status_text IS 'Gets the descriptive text for a part status including completed state';