-- Patch for messaging enhancements
-- Add attachments support to messages
alter table messages add column if not exists attachments jsonb default '[]'::jsonb;
alter table messages add column if not exists type text default 'text' check (type in ('text', 'attachment', 'audio', 'location'));
alter table messages add column if not exists metadata jsonb default '{}'::jsonb;

-- Ensure real-time is fully enabled for messages
alter table messages replica identity full;
