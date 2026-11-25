create table if not exists public.admin_settings (
  id integer primary key default 1 check (id = 1),
  admin_id text not null default 'azerty28',
  updated_at timestamptz not null default now()
);
insert into public.admin_settings (id, admin_id) values (1, 'azerty28') on conflict (id) do nothing;

create table if not exists public.portfolio_projects (
  id text primary key,
  title text not null,
  description text not null default '',
  logo_url text not null default '',
  logo_text text not null default '',
  techs jsonb not null default '[]'::jsonb,
  github_url text not null default '',
  live_url text not null default '',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.store_regions (
  id text primary key,
  name text not null,
  flag_url text not null default '',
  flag_text text not null default '',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.store_apps (
  id text primary key,
  region_id text not null references public.store_regions(id) on delete cascade,
  name text not null,
  logo_url text not null default '',
  logo_text text not null default '',
  description text not null default '',
  price_per_month text not null default '',
  checkout_url text not null default '',
  status text not null default 'AVAILABLE',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.bespoke_regions (
  id text primary key,
  name text not null,
  flag_url text not null default '',
  flag_text text not null default '',
  category_label text not null default 'SERVICES',
  sales_lead_secret_id text unique,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.bespoke_items (
  id text primary key,
  region_id text not null references public.bespoke_regions(id) on delete cascade,
  name text not null,
  price text not null default '',
  description text not null default '',
  category_label text not null default '',
  action_url text not null default '',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.calculator_settings (
  id integer primary key default 1 check (id = 1),
  commission_rate numeric not null default 0.17,
  delivery_cost_pct numeric not null default 0.30,
  payment_fee_pct numeric not null default 0.03,
  profit_target_pct numeric not null default 0.20,
  fx_buffer_pct numeric not null default 0.03,
  deals_required integer not null default 5,
  prices_in text not null default 'USD',
  updated_at timestamptz not null default now()
);
insert into public.calculator_settings (id) values (1) on conflict (id) do nothing;

create table if not exists public.region_salaries (
  id text primary key,
  name text not null,
  currency_code text not null,
  is_usd boolean not null default false,
  salary_min_usd numeric not null,
  salary_max_usd numeric not null,
  bespoke_region_id text,
  store_region_id text,
  sort_order integer not null default 0
);

create table if not exists public.fx_rates_locked (
  currency_code text primary key,
  rate_to_usd numeric not null,
  locked_on date not null default current_date,
  updated_at timestamptz not null default now()
);

create table if not exists public.globe_countries (
  id text primary key,
  name text not null,
  flag_text text not null default '',
  flag_url text not null default '',
  lat numeric not null default 0,
  lng numeric not null default 0,
  sales_team_active boolean not null default false,
  sales_team_size integer not null default 0,
  sales_lead text not null default '',
  products_shipped boolean not null default false,
  ship_count integer not null default 0,
  active_tools boolean not null default false,
  tools jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.country_journal (
  id text primary key,
  country_id text not null references public.globe_countries(id) on delete cascade,
  text text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.dev_applications (
  id text primary key,
  name text not null,
  country text not null,
  github_link text not null,
  email text not null,
  created_at timestamptz not null default now()
);

create or replace view public.bespoke_regions_public
with (security_invoker = false) as
select id, name, flag_url, flag_text, category_label, sort_order, created_at
from public.bespoke_regions
order by sort_order, created_at;

alter table public.admin_settings enable row level security;
alter table public.portfolio_projects enable row level security;
alter table public.store_regions enable row level security;
alter table public.store_apps enable row level security;
alter table public.bespoke_regions enable row level security;
alter table public.bespoke_items enable row level security;
alter table public.calculator_settings enable row level security;
alter table public.region_salaries enable row level security;
alter table public.fx_rates_locked enable row level security;
alter table public.globe_countries enable row level security;
alter table public.country_journal enable row level security;
alter table public.dev_applications enable row level security;

revoke all on public.admin_settings from anon, authenticated;
revoke all on public.bespoke_regions from anon, authenticated;
grant select on public.bespoke_regions_public to anon, authenticated;

drop policy if exists "Public read portfolio" on public.portfolio_projects;
create policy "Public read portfolio" on public.portfolio_projects for select using (true);
drop policy if exists "Public read store_regions" on public.store_regions;
create policy "Public read store_regions" on public.store_regions for select using (true);
drop policy if exists "Public read store_apps" on public.store_apps;
create policy "Public read store_apps" on public.store_apps for select using (true);
drop policy if exists "Public read bespoke_items" on public.bespoke_items;
create policy "Public read bespoke_items" on public.bespoke_items for select using (true);
drop policy if exists "Public read calculator_settings" on public.calculator_settings;
create policy "Public read calculator_settings" on public.calculator_settings for select using (true);
drop policy if exists "Public read region_salaries" on public.region_salaries;
create policy "Public read region_salaries" on public.region_salaries for select using (true);
drop policy if exists "Public read fx_rates_locked" on public.fx_rates_locked;
create policy "Public read fx_rates_locked" on public.fx_rates_locked for select using (true);
drop policy if exists "Public read globe_countries" on public.globe_countries;
create policy "Public read globe_countries" on public.globe_countries for select using (true);
drop policy if exists "Public read country_journal" on public.country_journal;
create policy "Public read country_journal" on public.country_journal for select using (true);
drop policy if exists "Public insert dev_applications" on public.dev_applications;
create policy "Public insert dev_applications" on public.dev_applications for insert with check (true);

insert into public.portfolio_projects (id, title, description, logo_text, techs, github_url, live_url, sort_order) values
  ('bxb-core', 'BXB CORE ENGINE', 'AUTONOMOUS WORKFLOW ORCHESTRATOR RUNNING 24/7/365 ON COMMAND.', 'BC', '["NODE.JS","RUST","DOCKER","REDIS"]'::jsonb, 'https://github.com/BXBK8', 'https://github.com/BXBK8', 1),
  ('ether-sync', 'ETHER SYNC', 'REAL-TIME DISTRIBUTED DATA MESH FOR TEAMS AND ENTERPRISE NODES.', 'ES', '["TYPESCRIPT","WEBSOCKETS","POSTGRES"]'::jsonb, 'https://github.com/BXBK8', 'https://github.com/BXBK8', 2),
  ('sentinel-bot', 'SENTINEL OPS', 'ZERO-DOWNTIME ROBOTIC MONITORING AND INSTANT COMMAND EXECUTION.', 'SO', '["PYTHON","FASTAPI","KUBERNETES"]'::jsonb, 'https://github.com/BXBK8', 'https://github.com/BXBK8', 3)
on conflict (id) do nothing;

insert into public.store_regions (id, name, flag_text, sort_order) values ('ghana', 'GHANA', 'GH', 1), ('mena', 'MENA', 'MN', 2) on conflict (id) do nothing;

insert into public.store_apps (id, region_id, name, logo_text, description, price_per_month, sort_order) values
  ('gh-automate', 'ghana', 'BXB AUTOMATE GH', 'BA', '24/7/365 AUTONOMOUS WORKFLOW ENGINE BUILT FOR GHANA TEAMS.', '$29 / MONTH', 1),
  ('gh-payflow', 'ghana', 'BXB PAYFLOW', 'BP', 'INSTANT MOBILE-MONEY & BUSINESS LEDGER SYNC ON COMMAND.', '$39 / MONTH', 2),
  ('mena-pulse', 'mena', 'BXB PULSE MENA', 'MP', 'REAL-TIME ENTERPRISE TELEMETRY AND COMMAND ROUTING ACROSS MENA.', '$49 / MONTH', 1),
  ('mena-vault', 'mena', 'BXB VAULT', 'BV', 'ENCRYPTED ETHER STORAGE AND ZERO-LATENCY API SYNC FOR ORGANISATIONS.', '$79 / MONTH', 2)
on conflict (id) do nothing;

insert into public.bespoke_regions (id, name, flag_text, category_label, sales_lead_secret_id, sort_order) values
  ('ghana', 'GHANA', 'GH', 'SERVICES', 'BXB-GH-2026', 1),
  ('mena', 'MENA', 'MN', 'SOLUTIONS', 'BXB-MN-2026', 2)
on conflict (id) do nothing;

insert into public.bespoke_items (id, region_id, name, price, description, category_label, sort_order) values
  ('gh-ai-ops', 'ghana', 'CUSTOM AI AUTOMATION', '$1,500', 'END-TO-END AUTONOMOUS AGENTS TAILORED FOR LOCAL TEAMS AND OPERATIONS.', 'SERVICES', 1),
  ('gh-web-sys', 'ghana', 'BESPOKE WEB SYSTEMS', '$2,200', 'HIGH-SPEED CUSTOM PLATFORMS BUILT TO RUN 24/7/365 ON YOUR COMMAND.', 'SERVICES', 2),
  ('mena-enterprise', 'mena', 'ENTERPRISE ETHER MESH', '$3,800', 'DEDICATED MULTI-REGION INFRASTRUCTURE AND REAL-TIME DATA PIPELINES.', 'SOLUTIONS', 1),
  ('mena-robotics', 'mena', 'ROBOTIC WORKFLOW SUITE', '$4,500', 'CUSTOM HARDWARE & SOFTWARE ORCHESTRATION FOR HIGH-VOLUME ORGANISATIONS.', 'SOLUTIONS', 2)
on conflict (id) do nothing;

insert into public.region_salaries (id, name, currency_code, is_usd, salary_min_usd, salary_max_usd, bespoke_region_id, store_region_id, sort_order) values
  ('gh', 'Ghana', 'GHS', false, 220, 220, 'ghana', 'ghana', 1),
  ('us', 'USA', 'USD', true, 4279, 5916, 'mena', 'mena', 2)
on conflict (id) do nothing;

insert into public.fx_rates_locked (currency_code, rate_to_usd, locked_on) values ('GHS', 0.0667, '2026-11-01'), ('USD', 1, '2026-11-01') on conflict (currency_code) do nothing;

insert into public.globe_countries (id, name, flag_text, lat, lng, sales_team_active, sales_team_size, sales_lead, products_shipped, ship_count, active_tools, tools) values
  ('gh', 'GHANA', 'GH', 7.9, -1.0, true, 4, 'KWAME MENSAH', true, 14, true, '["BXB AUTOMATE","BXB PAYFLOW"]'::jsonb),
  ('us', 'USA', 'US', 38.0, -97.0, true, 9, 'ELENA ROSTOVA', true, 42, false, '[]'::jsonb),
  ('ae', 'UAE', 'AE', 23.4, 53.8, false, 0, '', true, 11, true, '["BXB VAULT","BXB PULSE"]'::jsonb),
  ('sg', 'SINGAPORE', 'SG', 1.35, 103.8, false, 0, '', false, 0, true, '["BXB AUTOMATE"]'::jsonb)
on conflict (id) do nothing;

insert into public.country_journal (id, country_id, text, created_at) values
  ('j-gh-1', 'gh', 'ACCRA SALES DESK CLOSED 2 NEW BXB PAYFLOW ACCOUNTS.', now() - interval '2 hours'),
  ('j-gh-2', 'gh', 'BXB AUTOMATE NODE UPGRADED TO V2.4 ACROSS CLIENT FLEETS.', now() - interval '36 hours'),
  ('j-us-1', 'us', 'SHIPPED BATCH #42 HARDWARE UNITS TO EAST COAST PARTNERS.', now() - interval '7 hours'),
  ('j-us-2', 'us', 'NORTH AMERICA Q4 ENTERPRISE PIPELINE TARGET LOCKED.', now() - interval '72 hours'),
  ('j-ae-1', 'ae', 'BXB VAULT REAL-TIME SYNC ACTIVATED FOR DUBAI LOGISTICS HUB.', now() - interval '14 hours'),
  ('j-sg-1', 'sg', 'AUTONOMOUS WORKFLOW CLUSTER MAINTAINING 99.98% UPTIME.', now() - interval '48 hours')
on conflict (id) do nothing;
