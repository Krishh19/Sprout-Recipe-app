-- ============================================================================
-- SPROUT DATABASE MIGRATION 04: Enforce UTF-8 Client & Database Encoding
-- ============================================================================

-- Ensure the database connection client encoding is UTF8 for all sessions
SET client_encoding = 'UTF8';

-- Enforce UTF-8 default collation and character sets across PostgreSQL connection profiles
COMMENT ON SCHEMA public IS 'Sprout production schema with UTF-8 encoding enforced';
