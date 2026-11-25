create table if not exists public.connect_links (
  id integer primary key default 1 check (id = 1),
  discord_url text not null default 'https://discord.com',
  linkedin_url text not null default 'https://linkedin.com',
  github_url text not null default 'https://github.com/BXBK8',
  updated_at timestamptz not null default now()
);

insert into public.connect_links (id, discord_url, linkedin_url, github_url)
values (1, 'https://discord.com', 'https://linkedin.com', 'https://github.com/BXBK8')
on conflict (id) do nothing;

alter table public.connect_links enable row level security;
drop policy if exists "Public read connect_links" on public.connect_links;
create policy "Public read connect_links" on public.connect_links for select using (true);

create or replace function public.admin_update_connect_links(
  p_admin_id text,
  p_discord_url text,
  p_linkedin_url text,
  p_github_url text
) returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_admin(p_admin_id);
  insert into public.connect_links (id, discord_url, linkedin_url, github_url, updated_at)
  values (1, trim(p_discord_url), trim(p_linkedin_url), trim(p_github_url), now())
  on conflict (id) do update set
    discord_url = excluded.discord_url,
    linkedin_url = excluded.linkedin_url,
    github_url = excluded.github_url,
    updated_at = now();
end;
$$;

grant execute on function public.admin_update_connect_links(text, text, text, text) to anon, authenticated;
