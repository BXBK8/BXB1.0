create or replace function public._assert_admin(p_admin_id text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (
    select 1 from public.admin_settings
    where id = 1 and upper(admin_id) = upper(trim(coalesce(p_admin_id, '')))
  ) then
    raise exception 'UNAUTHORIZED_ADMIN';
  end if;
end;
$$;
revoke execute on function public._assert_admin(text) from public, anon, authenticated;

create or replace function public.verify_admin_id(p_admin_id text)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  return exists (
    select 1 from public.admin_settings
    where id = 1 and upper(admin_id) = upper(trim(coalesce(p_admin_id, '')))
  );
end;
$$;

create or replace function public.admin_update_admin_id(p_admin_id text, p_new_admin_id text)
returns boolean language plpgsql security definer set search_path = public as $$
declare v_clean text := upper(trim(coalesce(p_new_admin_id, '')));
begin
  perform public._assert_admin(p_admin_id);
  if v_clean = '' then return false; end if;
  update public.admin_settings set admin_id = v_clean, updated_at = now() where id = 1;
  return true;
end;
$$;

create or replace function public.admin_upsert_portfolio_project(
  p_admin_id text, p_id text, p_title text, p_description text, p_logo_url text, p_logo_text text,
  p_techs jsonb, p_github_url text, p_live_url text, p_sort_order integer
) returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  insert into public.portfolio_projects (id, title, description, logo_url, logo_text, techs, github_url, live_url, sort_order)
  values (p_id, p_title, coalesce(p_description,''), coalesce(p_logo_url,''), coalesce(p_logo_text,''), coalesce(p_techs,'[]'::jsonb), coalesce(p_github_url,''), coalesce(p_live_url,''), coalesce(p_sort_order,0))
  on conflict (id) do update set
    title = excluded.title, description = excluded.description, logo_url = excluded.logo_url,
    logo_text = excluded.logo_text, techs = excluded.techs, github_url = excluded.github_url,
    live_url = excluded.live_url, sort_order = excluded.sort_order;
end;
$$;

create or replace function public.admin_delete_portfolio_project(p_admin_id text, p_id text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  delete from public.portfolio_projects where id = p_id;
end;
$$;

create or replace function public.admin_reorder_portfolio_projects(p_admin_id text, p_ids jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare i integer; v_id text;
begin
  perform public._assert_admin(p_admin_id);
  for i in 0 .. jsonb_array_length(p_ids) - 1 loop
    v_id := p_ids ->> i;
    update public.portfolio_projects set sort_order = i + 1 where id = v_id;
  end loop;
end;
$$;

create or replace function public.admin_upsert_store_region(
  p_admin_id text, p_id text, p_name text, p_flag_url text, p_flag_text text, p_sort_order integer
) returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  insert into public.store_regions (id, name, flag_url, flag_text, sort_order)
  values (p_id, p_name, coalesce(p_flag_url,''), coalesce(p_flag_text,''), coalesce(p_sort_order,0))
  on conflict (id) do update set name = excluded.name, flag_url = excluded.flag_url, flag_text = excluded.flag_text, sort_order = excluded.sort_order;
end;
$$;

create or replace function public.admin_delete_store_region(p_admin_id text, p_id text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  delete from public.store_regions where id = p_id;
end;
$$;

create or replace function public.admin_upsert_store_app(
  p_admin_id text, p_id text, p_region_id text, p_name text, p_logo_url text, p_logo_text text,
  p_description text, p_price_per_month text, p_checkout_url text, p_status text, p_sort_order integer
) returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  insert into public.store_apps (id, region_id, name, logo_url, logo_text, description, price_per_month, checkout_url, status, sort_order)
  values (p_id, p_region_id, p_name, coalesce(p_logo_url,''), coalesce(p_logo_text,''), coalesce(p_description,''), coalesce(p_price_per_month,''), coalesce(p_checkout_url,''), coalesce(p_status,'AVAILABLE'), coalesce(p_sort_order,0))
  on conflict (id) do update set
    region_id = excluded.region_id, name = excluded.name, logo_url = excluded.logo_url, logo_text = excluded.logo_text,
    description = excluded.description, price_per_month = excluded.price_per_month, checkout_url = excluded.checkout_url,
    status = excluded.status, sort_order = excluded.sort_order;
end;
$$;

create or replace function public.admin_delete_store_app(p_admin_id text, p_id text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  delete from public.store_apps where id = p_id;
end;
$$;

create or replace function public.admin_get_bespoke_regions(p_admin_id text)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  return coalesce((select jsonb_agg(to_jsonb(r) order by r.sort_order, r.created_at) from public.bespoke_regions r), '[]'::jsonb);
end;
$$;

create or replace function public.admin_upsert_bespoke_region(
  p_admin_id text, p_id text, p_name text, p_flag_url text, p_flag_text text, p_category_label text, p_sort_order integer
) returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  insert into public.bespoke_regions (id, name, flag_url, flag_text, category_label, sort_order)
  values (p_id, p_name, coalesce(p_flag_url,''), coalesce(p_flag_text,''), coalesce(p_category_label,'SERVICES'), coalesce(p_sort_order,0))
  on conflict (id) do update set
    name = excluded.name, flag_url = excluded.flag_url, flag_text = excluded.flag_text,
    category_label = excluded.category_label, sort_order = excluded.sort_order;
end;
$$;

create or replace function public.admin_delete_bespoke_region(p_admin_id text, p_id text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  delete from public.bespoke_regions where id = p_id;
end;
$$;

create or replace function public.admin_generate_sales_lead_secret(p_admin_id text, p_region_id text)
returns text language plpgsql security definer set search_path = public as $$
declare v_code text; v_candidate text;
begin
  perform public._assert_admin(p_admin_id);
  v_code := upper(left(coalesce(p_region_id, 'RG'), 2));
  loop
    v_candidate := 'BXB-' || v_code || '-' || upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 4));
    exit when not exists (select 1 from public.bespoke_regions where sales_lead_secret_id = v_candidate and id <> p_region_id);
  end loop;
  update public.bespoke_regions set sales_lead_secret_id = v_candidate where id = p_region_id;
  return v_candidate;
end;
$$;

create or replace function public.admin_upsert_bespoke_item(
  p_admin_id text, p_id text, p_region_id text, p_name text, p_price text, p_description text, p_category_label text, p_action_url text, p_sort_order integer
) returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  insert into public.bespoke_items (id, region_id, name, price, description, category_label, action_url, sort_order)
  values (p_id, p_region_id, p_name, coalesce(p_price,''), coalesce(p_description,''), coalesce(p_category_label,''), coalesce(p_action_url,''), coalesce(p_sort_order,0))
  on conflict (id) do update set
    region_id = excluded.region_id, name = excluded.name, price = excluded.price,
    description = excluded.description, category_label = excluded.category_label,
    action_url = excluded.action_url, sort_order = excluded.sort_order;
end;
$$;

create or replace function public.admin_delete_bespoke_item(p_admin_id text, p_id text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  delete from public.bespoke_items where id = p_id;
end;
$$;

create or replace function public.sales_lead_login(p_secret_id text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_reg public.bespoke_regions%rowtype; v_items jsonb;
begin
  select * into v_reg from public.bespoke_regions
  where upper(sales_lead_secret_id) = upper(trim(coalesce(p_secret_id, ''))) limit 1;
  if not found then return null; end if;
  select coalesce(jsonb_agg(to_jsonb(it) order by it.sort_order, it.created_at), '[]'::jsonb)
  into v_items from public.bespoke_items it where it.region_id = v_reg.id;
  return jsonb_build_object('id', v_reg.id, 'name', v_reg.name, 'flag_url', v_reg.flag_url, 'flag_text', v_reg.flag_text, 'category_label', v_reg.category_label, 'items', v_items);
end;
$$;

create or replace function public.sales_lead_update_bespoke_price(p_secret_id text, p_item_id text, p_price text)
returns boolean language plpgsql security definer set search_path = public as $$
declare v_region_id text;
begin
  select id into v_region_id from public.bespoke_regions
  where upper(sales_lead_secret_id) = upper(trim(coalesce(p_secret_id, ''))) limit 1;
  if v_region_id is null then return false; end if;
  update public.bespoke_items set price = upper(trim(coalesce(p_price, ''))) where id = p_item_id and region_id = v_region_id;
  return found;
end;
$$;

create or replace function public.admin_upsert_globe_country(
  p_admin_id text, p_id text, p_name text, p_flag_text text, p_flag_url text, p_lat numeric, p_lng numeric,
  p_sales_team_active boolean, p_sales_team_size integer, p_sales_lead text,
  p_products_shipped boolean, p_ship_count integer, p_active_tools boolean, p_tools jsonb
) returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  insert into public.globe_countries (id, name, flag_text, flag_url, lat, lng, sales_team_active, sales_team_size, sales_lead, products_shipped, ship_count, active_tools, tools, updated_at)
  values (p_id, p_name, coalesce(p_flag_text,''), coalesce(p_flag_url,''), coalesce(p_lat,0), coalesce(p_lng,0), coalesce(p_sales_team_active,false), coalesce(p_sales_team_size,0), coalesce(p_sales_lead,''), coalesce(p_products_shipped,false), coalesce(p_ship_count,0), coalesce(p_active_tools,false), coalesce(p_tools,'[]'::jsonb), now())
  on conflict (id) do update set
    name = excluded.name, flag_text = excluded.flag_text, flag_url = excluded.flag_url, lat = excluded.lat, lng = excluded.lng,
    sales_team_active = excluded.sales_team_active, sales_team_size = excluded.sales_team_size, sales_lead = excluded.sales_lead,
    products_shipped = excluded.products_shipped, ship_count = excluded.ship_count, active_tools = excluded.active_tools,
    tools = excluded.tools, updated_at = now();
end;
$$;

create or replace function public.admin_delete_globe_country(p_admin_id text, p_id text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  delete from public.globe_countries where id = p_id;
end;
$$;

create or replace function public.admin_add_country_journal_entry(p_admin_id text, p_id text, p_country_id text, p_text text)
returns timestamptz language plpgsql security definer set search_path = public as $$
declare v_ts timestamptz := now();
begin
  perform public._assert_admin(p_admin_id);
  insert into public.country_journal (id, country_id, text, created_at) values (p_id, p_country_id, p_text, v_ts);
  return v_ts;
end;
$$;

create or replace function public.admin_delete_country_journal_entry(p_admin_id text, p_id text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  delete from public.country_journal where id = p_id;
end;
$$;

create or replace function public.admin_update_calculator_settings(
  p_admin_id text, p_commission_rate numeric, p_delivery_cost_pct numeric, p_payment_fee_pct numeric,
  p_profit_target_pct numeric, p_fx_buffer_pct numeric, p_deals_required integer
) returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  update public.calculator_settings set
    commission_rate = p_commission_rate, delivery_cost_pct = p_delivery_cost_pct,
    payment_fee_pct = p_payment_fee_pct, profit_target_pct = p_profit_target_pct,
    fx_buffer_pct = p_fx_buffer_pct, deals_required = p_deals_required, updated_at = now()
  where id = 1;
end;
$$;

create or replace function public.admin_upsert_region_salary(
  p_admin_id text, p_id text, p_name text, p_currency_code text, p_is_usd boolean,
  p_salary_min_usd numeric, p_salary_max_usd numeric, p_bespoke_region_id text, p_store_region_id text, p_sort_order integer
) returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  insert into public.region_salaries (id, name, currency_code, is_usd, salary_min_usd, salary_max_usd, bespoke_region_id, store_region_id, sort_order)
  values (p_id, p_name, p_currency_code, coalesce(p_is_usd,false), p_salary_min_usd, p_salary_max_usd, p_bespoke_region_id, p_store_region_id, coalesce(p_sort_order,0))
  on conflict (id) do update set
    name = excluded.name, currency_code = excluded.currency_code, is_usd = excluded.is_usd,
    salary_min_usd = excluded.salary_min_usd, salary_max_usd = excluded.salary_max_usd,
    bespoke_region_id = excluded.bespoke_region_id, store_region_id = excluded.store_region_id, sort_order = excluded.sort_order;
end;
$$;

create or replace function public.admin_delete_region_salary(p_admin_id text, p_id text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  delete from public.region_salaries where id = p_id;
end;
$$;

create or replace function public.admin_upsert_fx_rate(p_admin_id text, p_currency_code text, p_rate_to_usd numeric, p_locked_on date)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  insert into public.fx_rates_locked (currency_code, rate_to_usd, locked_on, updated_at)
  values (upper(p_currency_code), p_rate_to_usd, coalesce(p_locked_on, current_date), now())
  on conflict (currency_code) do update set rate_to_usd = excluded.rate_to_usd, locked_on = excluded.locked_on, updated_at = now();
end;
$$;

create or replace function public.admin_delete_fx_rate(p_admin_id text, p_currency_code text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  delete from public.fx_rates_locked where currency_code = upper(p_currency_code);
end;
$$;

create or replace function public.admin_get_dev_applications(p_admin_id text)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  return coalesce((select jsonb_agg(to_jsonb(d) order by d.created_at desc) from public.dev_applications d), '[]'::jsonb);
end;
$$;

create or replace function public.admin_delete_dev_application(p_admin_id text, p_id text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  delete from public.dev_applications where id = p_id;
end;
$$;

grant execute on function public.verify_admin_id(text) to anon, authenticated;
grant execute on function public.admin_update_admin_id(text, text) to anon, authenticated;
grant execute on function public.admin_upsert_portfolio_project(text, text, text, text, text, text, jsonb, text, text, integer) to anon, authenticated;
grant execute on function public.admin_delete_portfolio_project(text, text) to anon, authenticated;
grant execute on function public.admin_reorder_portfolio_projects(text, jsonb) to anon, authenticated;
grant execute on function public.admin_upsert_store_region(text, text, text, text, text, integer) to anon, authenticated;
grant execute on function public.admin_delete_store_region(text, text) to anon, authenticated;
grant execute on function public.admin_upsert_store_app(text, text, text, text, text, text, text, text, text, text, integer) to anon, authenticated;
grant execute on function public.admin_delete_store_app(text, text) to anon, authenticated;
grant execute on function public.admin_get_bespoke_regions(text) to anon, authenticated;
grant execute on function public.admin_upsert_bespoke_region(text, text, text, text, text, text, integer) to anon, authenticated;
grant execute on function public.admin_delete_bespoke_region(text, text) to anon, authenticated;
grant execute on function public.admin_generate_sales_lead_secret(text, text) to anon, authenticated;
grant execute on function public.admin_upsert_bespoke_item(text, text, text, text, text, text, text, text, integer) to anon, authenticated;
grant execute on function public.admin_delete_bespoke_item(text, text) to anon, authenticated;
grant execute on function public.sales_lead_login(text) to anon, authenticated;
grant execute on function public.sales_lead_update_bespoke_price(text, text, text) to anon, authenticated;
grant execute on function public.admin_upsert_globe_country(text, text, text, text, text, numeric, numeric, boolean, integer, text, boolean, integer, boolean, jsonb) to anon, authenticated;
grant execute on function public.admin_delete_globe_country(text, text) to anon, authenticated;
grant execute on function public.admin_add_country_journal_entry(text, text, text, text) to anon, authenticated;
grant execute on function public.admin_delete_country_journal_entry(text, text) to anon, authenticated;
grant execute on function public.admin_update_calculator_settings(text, numeric, numeric, numeric, numeric, numeric, integer) to anon, authenticated;
grant execute on function public.admin_upsert_region_salary(text, text, text, text, boolean, numeric, numeric, text, text, integer) to anon, authenticated;
grant execute on function public.admin_delete_region_salary(text, text) to anon, authenticated;
grant execute on function public.admin_upsert_fx_rate(text, text, numeric, date) to anon, authenticated;
grant execute on function public.admin_delete_fx_rate(text, text) to anon, authenticated;
grant execute on function public.admin_get_dev_applications(text) to anon, authenticated;
grant execute on function public.admin_delete_dev_application(text, text) to anon, authenticated;
