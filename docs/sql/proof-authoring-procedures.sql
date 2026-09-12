-- proof-authoring-procedures.sql
--
-- First proof of the reusable model-authoring procedures.
-- Run ONE step at a time. Each EXEC autocommits when run on its own; run the CLI
-- invoke printed above it before moving to the next step. The point is that the
-- SQL data changes and the unchanged CLI observes the changed output -- no
-- capability-specific source file participates.
--
-- Prerequisite: docs/sql/authoring-procedures.sql installed, and the current
-- analysis.v_capability_execution_declaration view installed (the version whose
-- `def` CTE selects the latest definition per semantic object, so a reconfigured
-- mechanic replaces its predecessor instead of appending a duplicate).

-- Step 1. Scaffold Hello World. Behavior when it already exists: REPLACE.
EXEC model.scaffold_capability
  @capability_id    = N'hello-world-sql',
  @greeting_template = N'Hello {name}!';
-- sfx capability invoke hello-world-sql --input 'Sidney'    -> message: "Hello Sidney!"
GO

-- Step 2. Change the greeting through the configuration procedure. Returns the
-- before/after template.
EXEC model.configure_mechanic
  @capability_id    = N'hello-world-sql',
  @greeting_template = N'Howdy {name}!';
-- sfx capability invoke hello-world-sql --input 'Sidney'    -> message: "Howdy Sidney!"
GO

-- Step 3. Inspect the assembled meaning, contracts, mechanic, example and any
-- unresolved references.
EXEC model.inspect_capability @capability_id = N'hello-world-sql';
GO

-- Step 4. Scaffold a second identity with the same pattern.
EXEC model.scaffold_capability
  @capability_id    = N'hello-world-2',
  @greeting_template = N'Hi {name}!';
-- sfx capability invoke hello-world-2 --input 'Sidney'      -> message: "Hi Sidney!"
GO
